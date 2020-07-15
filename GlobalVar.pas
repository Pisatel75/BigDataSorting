unit GlobalVar;

interface

uses
  Vcl.Dialogs,System.SysUtils;

const
  InitialDataFile='data.txt';   // ��� ��������� ���������� ����� ��� ����������
  MemoryLimit=100;              // ���������� ������ �������� ����� ������ � ������ �� 500 �������� ��� ���������� "� ���"
  StringCompareLength=50;       // ���������� ����� �������� ��������� �����

type
  ProcessRec=record
    Size:Int64;
    Flag:Boolean;
    Progress:Int64;
    Level:Integer;
    ID:Cardinal;
    Free:Boolean;
  end;
  StringRec=record
    CurStr:AnsiString;
    SizeOfCurStr:Integer;
  end;
  ResNamesRec=record
    RealName:String;
    BinName:String;
  end;
  PositionSystem256Mas=array[0..StringCompareLength] of Integer;

var
  // ���������� ����������
  TotalCount,ZeroCount,TotalReady:Int64;
  CurrentLevel:Integer;
  WorkFlag:Boolean;
  // ���������� �������
  Processes:array[1..4] of ProcessRec;

  // ���������� ��������� � �������
  function FileSeparate(NameOfDataFile,NameOfLeftFile,NameOfRightFile:String;
                        CountOfDataFileBlocks:Int64; var CountOfLeftFileBlocks,CountOfRightFileBlocks:Int64):Boolean;
  function CompareTwoStrings(StringOne,StringTwo:StringRec):Integer;
  function MiddleString(StringOne,StringTwo:StringRec):StringRec;
  function Bin(x:Integer):string;
  function BinToDec(x:string):Integer;
  Procedure ResultConstuct;

implementation

// ******************************************************************************************************************
// ������� ���������� ���������� ����� �� ��� ��������������� ����� - "������" � "�����".
// � ������ ������ ���������� "true", � ���� ��������� ���� ������������ � ������, �� "false".
// � ������ "true" �� ������ ��� ����� � ��������� ������� � ���������� ���������,
// � � ������ "false" - �������� ���������� � ����� ����� � ��������������� ��� �������� � ������
// ******************************************************************************************************************
function FileSeparate(NameOfDataFile,NameOfLeftFile,NameOfRightFile:String;
                      CountOfDataFileBlocks:Int64; var CountOfLeftFileBlocks,CountOfRightFileBlocks:Int64):Boolean;
var
  InitDataFile,LeftFile,RightFile:TextFile;
  i,j,WorkInt:Integer;
  Letter:AnsiChar;
  WorkStr:AnsiString;
  FlagCRLF,FlagFirstBlock:Boolean;
  DataFileMas:array[0..MemoryLimit] of StringRec;
begin
  // �������������� ����������
  FlagCRLF:=false;
  // ���������� ��� ���������� �������
  if CountOfDataFileBlocks<=MemoryLimit then
    begin
      // ��������� ���� � ������
      Result:=false;
      // ������ ������� ���� ����������� ������ �����
      AssignFile(InitDataFile,NameOfDataFile);
      Reset(InitDataFile);
      i:=0;
      DataFileMas[0].CurStr:='';
      DataFileMas[0].SizeOfCurStr:=0;
      // ������ ������� ���� �����������
      Repeat
        // ������ ������� ������
        Read(InitDataFile,Letter);
        if Letter=Chr(13) then
          begin
            FlagCRLF:=true;
          end
        else
          begin
            if (Letter=Chr(10)) and FlagCRLF then
              begin
                // ���������� CRLF
                Inc(i);
                DataFileMas[i].CurStr:='';
                DataFileMas[i].SizeOfCurStr:=0;
              end
            else
              begin
                // ���������� CRLF �����������
                if FlagCRLF then
                  begin
                    // � ������ ������ Chr(13) - ��� ����� ����������� ������
                    DataFileMas[i].CurStr:=DataFileMas[i].CurStr+Chr(13)+Letter;
                    DataFileMas[i].SizeOfCurStr:=DataFileMas[i].SizeOfCurStr+2;
                  end
                else
                  begin
                    // � ������ ������ Chr(10) - ��� ����� ����������� ������
                    DataFileMas[i].CurStr:=DataFileMas[i].CurStr+Letter;
                    DataFileMas[i].SizeOfCurStr:=DataFileMas[i].SizeOfCurStr+1;
                  end;
              end;
            FlagCRLF:=false;
          end;
      Until EoF(InitDataFile);
      CloseFile(InitDataFile);
      // ��������� ������������ ������� ���������� ������ ����� �� ����������� � ���������� �������
      // �� �������� ��� ��������, ��� ������ "BCD" ������ ������ "BCDEF", �� ������ ������ "ABC"
      for i:=0 to CountOfDataFileBlocks-2 do
        begin
          for j:=i+1 to CountOfDataFileBlocks-1 do
            begin
              // ���������� ������ ����� �����
              if CompareTwoStrings(DataFileMas[i],DataFileMas[j])>0 then
                begin
                  WorkStr:=DataFileMas[i].CurStr;
                  WorkInt:=DataFileMas[i].SizeOfCurStr;
                  DataFileMas[i].CurStr:=DataFileMas[j].CurStr;
                  DataFileMas[i].SizeOfCurStr:=DataFileMas[j].SizeOfCurStr;
                  DataFileMas[j].CurStr:=WorkStr;
                  DataFileMas[j].SizeOfCurStr:=WorkInt;
                end;
            end;
        end;
      // ��������� ���������� ������������� ������ � ����
      AssignFile(LeftFile,NameOfLeftFile);
      Rewrite(LeftFile);
      for i:=0 to CountOfDataFileBlocks-1 do
        begin
          for j:=1 to DataFileMas[i].SizeOfCurStr do
            begin
              Write(LeftFile,DataFileMas[i].CurStr[j]);
            end;
          Write(LeftFile,Chr(13)+Chr(10));
        end;
      CloseFile(LeftFile);
      CountOfLeftFileBlocks:=CountOfDataFileBlocks;
      CountOfRightFileBlocks:=0;
    end
  else
    begin
      // ����� ������� ���� �� ��� �������������� ����� � ��������� �������
      Result:=true;
      // �������������� ���������� � �������
      DataFileMas[0].CurStr:='';
      DataFileMas[0].SizeOfCurStr:=0;
      // MINIMUM
      DataFileMas[1].CurStr:='';
      DataFileMas[1].SizeOfCurStr:=0;
      // MAXIMUM
      DataFileMas[2].CurStr:='';
      DataFileMas[2].SizeOfCurStr:=0;
      FlagFirstBlock:=true;
      // ������ �������� ���� ����������� (������ ������ ��� ������ ���������� ��������)
      AssignFile(InitDataFile,NameOfDataFile);
      Reset(InitDataFile);
      Repeat
        // ������ ������� ������
        Read(InitDataFile,Letter);
        if Letter=Chr(13) then
          begin
            FlagCRLF:=true;
          end
        else
          begin
            if (Letter=Chr(10)) and FlagCRLF then
              begin
                // ����� ������ - ��������� � "��������"
                if FlagFirstBlock then
                  begin
                    FlagFirstBlock:=false;
                  end
                else
                  begin
                    if CompareTwoStrings(DataFileMas[1],DataFileMas[0])>0 then
                      begin
                        // MINIMUM
                        DataFileMas[1].CurStr:=DataFileMas[0].CurStr;
                        DataFileMas[1].SizeOfCurStr:=DataFileMas[0].SizeOfCurStr;
                      end;
                    if CompareTwoStrings(DataFileMas[0],DataFileMas[2])>0 then
                      begin
                        // MAXIMUM
                        DataFileMas[2].CurStr:=DataFileMas[0].CurStr;
                        DataFileMas[2].SizeOfCurStr:=DataFileMas[0].SizeOfCurStr;
                      end;
                  end;
                DataFileMas[0].CurStr:='';
                DataFileMas[0].SizeOfCurStr:=0;
              end
            else
              begin
                // ���������� CRLF �����������
                if FlagCRLF then
                  begin
                    // � ������ ������ Chr(13) - ��� ����� ����������� ������
                    if FlagFirstBlock then
                      begin
                        // �������� ��������� ��������
                        DataFileMas[1].CurStr:=DataFileMas[1].CurStr+Chr(13)+Letter;
                        DataFileMas[1].SizeOfCurStr:=DataFileMas[1].SizeOfCurStr+2;
                        DataFileMas[2].CurStr:=DataFileMas[2].CurStr+Chr(13)+Letter;
                        DataFileMas[2].SizeOfCurStr:=DataFileMas[2].SizeOfCurStr+2;
                      end
                    else
                      begin
                        // �������� ������ ��� ���������
                        DataFileMas[0].CurStr:=DataFileMas[0].CurStr+Chr(13)+Letter;
                        DataFileMas[0].SizeOfCurStr:=DataFileMas[0].SizeOfCurStr+2;
                      end;
                  end
                else
                  begin
                    // � ������ ������ Chr(10) - ��� ����� ����������� ������
                    if FlagFirstBlock then
                      begin
                        // �������� ��������� ��������
                        DataFileMas[1].CurStr:=DataFileMas[1].CurStr+Letter;
                        DataFileMas[1].SizeOfCurStr:=DataFileMas[1].SizeOfCurStr+1;
                        DataFileMas[2].CurStr:=DataFileMas[2].CurStr+Letter;
                        DataFileMas[2].SizeOfCurStr:=DataFileMas[2].SizeOfCurStr+1;
                      end
                    else
                      begin
                        // �������� ������ ��� ���������
                        DataFileMas[0].CurStr:=DataFileMas[0].CurStr+Letter;
                        DataFileMas[0].SizeOfCurStr:=DataFileMas[0].SizeOfCurStr+1;
                      end;
                  end;
              end;
            FlagCRLF:=false;
          end;
      Until EoF(InitDataFile);
      CloseFile(InitDataFile);
      // ��������� ������� �� ������� �������
      DataFileMas[3]:=MiddleString(DataFileMas[1],DataFileMas[2]);
      // �������������� ���������� � �������
      DataFileMas[0].CurStr:='';
      DataFileMas[0].SizeOfCurStr:=0;
      CountOfLeftFileBlocks:=0;
      CountOfRightFileBlocks:=0;
      // ��������� ���� �� ������� � ������� ����� (������ ������ ��������� �����)
      AssignFile(InitDataFile,NameOfDataFile);
      Reset(InitDataFile);
      AssignFile(LeftFile,NameOfLeftFile);
      Rewrite(LeftFile);
      AssignFile(RightFile,NameOfRightFile);
      Rewrite(RightFile);
      Repeat
        // ������ ������� ������
        Read(InitDataFile,Letter);
        if Letter=Chr(13) then
          begin
            FlagCRLF:=true;
          end
        else
          begin
            if (Letter=Chr(10)) and FlagCRLF then
              begin
                // ����� ������ - ��������� � "��������"
                if CompareTwoStrings(DataFileMas[3],DataFileMas[0])>0 then
                  begin
                    // LEFT
                    for i:=1 to DataFileMas[0].SizeOfCurStr do
                      begin
                        Write(LeftFile,DataFileMas[0].CurStr[i]);
                      end;
                    Write(LeftFile,Chr(13)+Chr(10));
                    CountOfLeftFileBlocks:=CountOfLeftFileBlocks+1;
                  end
                else
                  begin
                    // RIGHT
                    for i:=1 to DataFileMas[0].SizeOfCurStr do
                      begin
                        Write(RightFile,DataFileMas[0].CurStr[i]);
                      end;
                    Write(RightFile,Chr(13)+Chr(10));
                    CountOfRightFileBlocks:=CountOfRightFileBlocks+1;
                  end;
                DataFileMas[0].CurStr:='';
                DataFileMas[0].SizeOfCurStr:=0;
              end
            else
              begin
                // ���������� CRLF �����������
                if FlagCRLF then
                  begin
                    // � ������ ������ Chr(13) - ��� ����� ����������� ������
                    DataFileMas[0].CurStr:=DataFileMas[0].CurStr+Chr(13)+Letter;
                    DataFileMas[0].SizeOfCurStr:=DataFileMas[0].SizeOfCurStr+2;
                  end
                else
                  begin
                    // � ������ ������ Chr(10) - ��� ����� ����������� ������
                    DataFileMas[0].CurStr:=DataFileMas[0].CurStr+Letter;
                    DataFileMas[0].SizeOfCurStr:=DataFileMas[0].SizeOfCurStr+1;
                  end;
              end;
            FlagCRLF:=false;
          end;
      Until EoF(InitDataFile);
      CloseFile(InitDataFile);
      CloseFile(LeftFile);
      CloseFile(RightFile);
    end;
end;

// **********************************************************************************************************
// ������� ��������� ���� ����� ����� �� ����� StringCompareLength �������� ��� ���������� �� ��������.
// ���������� ��������� � ���� :
//                                -1 - ���� ������ ������ ������ ������;
//                                 0 - ���� ������ ����������;
//                                +1 - ���� ������ ������ ������ ������
// **********************************************************************************************************
function CompareTwoStrings(StringOne,StringTwo:StringRec):Integer;
var
  i,ZeroSum,LengthToCompareOne,LengthToCompareTwo:Integer;
  Sys256ofStringOne,Sys256ofStringTwo,Work256:PositionSystem256Mas;
  StringToCompareOne,StringToCompareTwo:AnsiString;
begin
  // �������� ������
  if StringOne.SizeOfCurStr>StringCompareLength then
    begin
      LengthToCompareOne:=StringCompareLength;
      StringToCompareOne:=Copy(StringOne.CurStr,1,StringCompareLength);
    end
  else
    begin
      LengthToCompareOne:=StringOne.SizeOfCurStr;
      StringToCompareOne:=StringOne.CurStr;
    end;
  if StringTwo.SizeOfCurStr>StringCompareLength then
    begin
      LengthToCompareTwo:=StringCompareLength;
      StringToCompareTwo:=Copy(StringTwo.CurStr,1,StringCompareLength);
    end
  else
    begin
      LengthToCompareTwo:=StringTwo.SizeOfCurStr;
      StringToCompareTwo:=StringTwo.CurStr;
    end;
  // �������������� �������
  for i:=0 to StringCompareLength do
    begin
      Work256[i]:=0;
      Sys256ofStringOne[i]:=0;
      Sys256ofStringTwo[i]:=0;
    end;
  // ����������� ������
  if LengthToCompareOne>0 then
    begin
      for i:=1 to LengthToCompareOne do
        begin
          Sys256ofStringOne[i]:=Ord(StringToCompareOne[i]);
        end;
    end;
  if LengthToCompareTwo>0 then
    begin
      for i:=1 to LengthToCompareTwo do
        begin
          Sys256ofStringTwo[i]:=Ord(StringToCompareTwo[i]);
        end;
    end;
  // ������� ������� ����� ���������������� ��������
  for i:=1 to StringCompareLength do
    begin
      Work256[i]:=Sys256ofStringOne[i]-Sys256ofStringTwo[i];
    end;
  ZeroSum:=0;
  for i:=StringCompareLength downto 1 do
    begin
      if Work256[i]<0 then
        begin
          Work256[i]:=Work256[i]+256;
          Work256[i-1]:=Work256[i-1]-1;
        end;
      ZeroSum:=ZeroSum+Work256[i];
    end;
  // ������� ���������
  Result:=Work256[0];
  if (Result=0) and (ZeroSum>0) then
    begin
      Result:=1;
    end;
end;

// **********************************************************************************************************
// ������� ���������� ��������� ������ �� ������ ���� ����� ����� �� ����� StringCompareLength ��������.
// ���������� ��������� � ���� ������� �� ���������� ��������� ������ � � ����� � ��������� ���������� CRLF
// **********************************************************************************************************
function MiddleString(StringOne,StringTwo:StringRec):StringRec;
var
  i,LengthToCompareOne,LengthToCompareTwo,EndPosition:Integer;
  Sys256ofStringOne,Sys256ofStringTwo,Sum256,Middle256:PositionSystem256Mas;
  StringToCompareOne,StringToCompareTwo:AnsiString;
begin
  // �������� ������
  if StringOne.SizeOfCurStr>StringCompareLength then
    begin
      LengthToCompareOne:=StringCompareLength;
      StringToCompareOne:=Copy(StringOne.CurStr,1,StringCompareLength);
    end
  else
    begin
      LengthToCompareOne:=StringOne.SizeOfCurStr;
      StringToCompareOne:=StringOne.CurStr;
    end;
  if StringTwo.SizeOfCurStr>StringCompareLength then
    begin
      LengthToCompareTwo:=StringCompareLength;
      StringToCompareTwo:=Copy(StringTwo.CurStr,1,StringCompareLength);
    end
  else
    begin
      LengthToCompareTwo:=StringTwo.SizeOfCurStr;
      StringToCompareTwo:=StringTwo.CurStr;
    end;
  // �������������� �������
  for i:=0 to StringCompareLength do
    begin
      Sum256[i]:=0;
      Sys256ofStringOne[i]:=0;
      Sys256ofStringTwo[i]:=0;
    end;
  // ����������� ������
  if LengthToCompareOne>0 then
    begin
      for i:=1 to LengthToCompareOne do
        begin
          Sys256ofStringOne[i]:=Ord(StringToCompareOne[i]);
        end;
    end;
  if LengthToCompareTwo>0 then
    begin
      for i:=1 to LengthToCompareTwo do
        begin
          Sys256ofStringTwo[i]:=Ord(StringToCompareTwo[i]);
        end;
    end;
  // ������� ����� ���� ��������������� �����
  for i:=1 to StringCompareLength do
    begin
      Sum256[i]:=Sys256ofStringOne[i]+Sys256ofStringTwo[i];
    end;
  for i:=StringCompareLength downto 1 do
    begin
      if Sum256[i]>255 then
        begin
          Sum256[i]:=Sum256[i]-256;
          Sum256[i-1]:=Sum256[i-1]+1;
        end;
    end;
  // ����� ���������� 256������ ����� �������
  // ������ ����� | ������  | ������  | ������  | ������  | ������  | �������� | �������� | �������� | �������� | �������� |
  // ������ ����� | 0 ��� 1 | 2 ��� 3 | 4 ��� 5 | 6 ��� 7 | 8 ��� 9 | 0 ��� 1  | 2 ��� 3  | 4 ��� 5  | 6 ��� 7  | 8 ��� 9  |
  // ���������    |    0    |    1    |    2    |    3    |    4    |    5     |    6     |    7     |    8     |    9     |
  Middle256[0]:=Sum256[0] div 2;
  for i:=1 to StringCompareLength do
    begin
      if (Sum256[i-1] div 2)=0 then
        begin
          Middle256[i]:=Sum256[i] div 2;
        end
      else
        begin
          Middle256[i]:=128+(Sum256[i] div 2);
        end;
    end;
  // ������� ���������
  EndPosition:=StringCompareLength;
  for i:=StringCompareLength downto 1 do
    begin
      if Middle256[i]>0 then
        begin
          EndPosition:=i;
          Break;
        end;
    end;
  Result.CurStr:='';
  Result.SizeOfCurStr:=EndPosition;
  for i:=1 to EndPosition-1 do
    begin
      if (Middle256[i]=13) and (Middle256[i+1]=10) then
        begin
          Middle256[i+1]:=11;
        end;
      Result.CurStr:=Result.CurStr+Chr(Middle256[i]);
    end;
  Result.CurStr:=Result.CurStr+Chr(Middle256[EndPosition]);
end;

//*******************************************************
//  ������� �������� ����� � �������� ������� ���������
//*******************************************************
function Bin(x:Integer):string;
const
  t:array[0..1] of char=('0','1');
var
  d:0..1;
begin
  Result:='';
  while (x<>0) do
    begin
      d:=x mod 2;
      Result:=t[d]+Result;
      x:=x div 2;
    end;
end;

//*********************************************************************
//  ������� �������� ����� �� �������� � ���������� ������� ���������
//*********************************************************************
function BinToDec(x:string):Integer;
var
  i,j,a:Integer;
begin
  Result:=StrToInt(x[Length(x)]);
  if Length(x)>1 then
    begin
      for i:=Length(x)-1 downto 1 do
        begin
          a:=1;
          for j:=i to Length(x)-1 do
            begin
              a:=a*2;
            end;
          Result:=Result+StrToInt(x[i])*a;
        end;
    end;
end;

//*******************************************************
//  ��������� ���������� ����� ����������� ����������
//*******************************************************
Procedure ResultConstuct;
var
  i,j,MainFilesCount,MaxBinLength,Len:Integer;
  ResultFile,TextData,WorkFile:TextFile;
  sr:TSearchRec;
  ResNames:ResNamesRec;
  WorkText:String;
  Letter:AnsiChar;
  FlagFirst:Boolean;
  Minimum:Int64;
begin
  MaxBinLength:=0;
  if FindFirst('*.re', faAnyFile, sr) = 0 then
    begin
      MainFilesCount:=0;
      repeat
        MainFilesCount:=MainFilesCount+1;
        ResNames.RealName:=Copy(sr.name,1,Pos('.',sr.name)-1);
        ResNames.BinName:=Bin(StrToInt(ResNames.RealName));
        if Length(ResNames.BinName)>MaxBinLength then
          begin
            MaxBinLength:=Length(ResNames.BinName);
          end;
      until FindNext(sr) <> 0;
      FindClose(sr);
    end;
  // ����������� �������� ����� � ��������������� �����
  for i:=1 to MainFilesCount do
    begin
      if FindFirst('*.re', faAnyFile, sr) = 0 then
        begin
          ResNames.RealName:=Copy(sr.name,1,Pos('.',sr.name)-1);
          ResNames.BinName:=Bin(StrToInt(ResNames.RealName));
          WorkText:=ResNames.BinName;
          ResNames.BinName:=WorkText+'1';
          Len:=Length(WorkText);
          for j:=Len to MaxBinLength+1 do
            begin
              WorkText:=ResNames.BinName;
              ResNames.BinName:=WorkText+'0';
            end;
          RenameFile(sr.name,IntToStr(BinToDec(ResNames.BinName))+'.res');
          FindClose(sr);
        end;
    end;
  // �������� ���� ���������� result.txt � ������� ������� �����
  AssignFile(ResultFile,'result.txt');
  Rewrite(ResultFile);
  for i:=1 to MainFilesCount do
    begin
      // ����� ������������ ������ �����
      if FindFirst('*.res', faAnyFile, sr) = 0 then
        begin
          FlagFirst:=true;
          repeat
            ResNames.BinName:=Copy(sr.name,1,Pos('.',sr.name)-1);
            if FlagFirst then
              begin
                FlagFirst:=false;
                Minimum:=StrToInt(ResNames.BinName);
              end
            else
              begin
                if Minimum>StrToInt(ResNames.BinName) then
                  begin
                    Minimum:=StrToInt(ResNames.BinName);
                  end;
              end;
          until FindNext(sr) <> 0;
          FindClose(sr);
        end;
      // ������� ��������� ���� � ����������� �������
      AssignFile(TextData,IntToStr(Minimum)+'.res');
      Reset(TextData);
      repeat
        read(TextData,letter);
        write(ResultFile,letter);
      until EoF(TextData);
      CloseFile(TextData);
      DeleteFile(IntToStr(Minimum)+'.res');
    end;
  CloseFile(ResultFile);
  ShowMessage('���������� ������� ���������!'+Chr(13)+'�������� ����: data.txt'+Chr(13)+'���������: zero.txt � result.txt');
end;

end.
