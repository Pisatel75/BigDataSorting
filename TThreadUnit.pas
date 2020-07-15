unit TThreadUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, GlobalVar, Vcl.Dialogs;

type
  DecompProcess = class(TThread)
  private
    { Private declarations }
  protected
    procedure Execute; override;
  end;

implementation

{ DecompProcess }

procedure DecompProcess.Execute;
var
  sr:TSearchRec;
  FlagID,SeparateRes:Boolean;
  WorkStr,LeftName,RightName,BinStr:String;
  CountLeft,CountRight:Int64;
  i,MainFilesCount,NumberOfProcess:Integer;
begin
  Self.FreeOnTerminate:=true;
  FlagID:=true;
  for i:=1 to 4 do
    begin
      if (Processes[i].ID=0) and FlagID then
        begin
          Processes[i].ID:=Self.ThreadID;
          NumberOfProcess:=i;
          FlagID:=false;
        end;
    end;
  while (not Terminated) and (Processes[NumberOfProcess].Flag) do
    begin
      MainFilesCount:=1;
      repeat
        Processes[NumberOfProcess].Level:=Processes[NumberOfProcess].Level+1;
        // ������ ������ ���������� ��� �����
        if FindFirst('*_'+IntToStr(Processes[NumberOfProcess].Level-1)+'.'+IntToStr(NumberOfProcess)+'pr', faAnyFile, sr) = 0 then
          begin
            repeat
              // ��������� ��� ���������� ����� ��� ������������� ����������� ��� ���������
              WorkStr:=sr.name;
              // ������� ������
              Delete(WorkStr,1,Pos('_',WorkStr));
              // �������� ���������� ���������� ����� � ����������� ��� � �������� ������
              BinStr:=Bin(StrToInt(Copy(WorkStr,1,Pos('_',WorkStr)-1)));
              // ��������� ����� ����� � ������ ����� ��� �������� ������� � ������
              LeftName:=IntToStr(BinToDec(BinStr+'0'))+'_0_'+IntToStr(Processes[NumberOfProcess].Level)+'.'+IntToStr(NumberOfProcess)+'pr';
              RightName:=IntToStr(BinToDec(BinStr+'1'))+'_1_'+IntToStr(Processes[NumberOfProcess].Level)+'.'+IntToStr(NumberOfProcess)+'pr';
              // ��������� �� ��� ����� ��������� ����
              repeat
                // ���� �������� ����������
              until WorkFlag;
              WorkFlag:=false;
              SeparateRes:=FileSeparate(sr.name,LeftName,RightName,
                                        StrToInt(Copy(sr.name,1,Pos('_',sr.name)-1)),CountLeft,CountRight);
              WorkFlag:=true;
              if SeparateRes then
                begin
                  // ���� ������� �������� �� ��� ����� - ��������������� �� �������� ������ � ������ �����
                  repeat
                    // ���� �������� ����������
                  until WorkFlag;
                  WorkFlag:=false;
                  RenameFile(LeftName,IntToStr(CountLeft)+'_'+LeftName);
                  WorkFlag:=true;
                  repeat
                    // ���� �������� ����������
                  until WorkFlag;
                  WorkFlag:=false;
                  RenameFile(RightName,IntToStr(CountRight)+'_'+RightName);
                  WorkFlag:=true;
                  MainFilesCount:=MainFilesCount+1;
                end
              else
                begin
                  // �������� ���� ��������������� ���� - ��������������� ��� � ������ [���������� �����].res
                  WorkStr:=IntToStr(BinToDec(BinStr+'0'))+'.re';
                  repeat
                    // ���� �������� ����������
                  until WorkFlag;
                  WorkFlag:=false;
                  RenameFile(LeftName,WorkStr);
                  WorkFlag:=true;
                  MainFilesCount:=MainFilesCount-1;
                  Processes[NumberOfProcess].Progress:=Processes[NumberOfProcess].Progress+CountLeft;
                end;
              // ������� ������������ �������� ����
              repeat
                // ���� �������� ����������
              until WorkFlag;
              WorkFlag:=false;
              DeleteFile(sr.name);
              WorkFlag:=true;
            until FindNext(sr) <> 0;
            FindClose(sr);
          end;
      until MainFilesCount=0;
      // ������ ��������� - ������ �������� �������������, ��������� ������� � ������� ������� �����
      Processes[NumberOfProcess].Flag:=false;
    end;
end;

end.
