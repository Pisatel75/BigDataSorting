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
        // Читаем первое попавшееся имя файла
        if FindFirst('*_'+IntToStr(Processes[NumberOfProcess].Level-1)+'.'+IntToStr(NumberOfProcess)+'pr', faAnyFile, sr) = 0 then
          begin
            repeat
              // Разбираем имя найденного файла для классификации результатов его обработки
              WorkStr:=sr.name;
              // Удаляем размер
              Delete(WorkStr,1,Pos('_',WorkStr));
              // Вынимаем уникальный десятичный номер и преобразуем его в двоичную строку
              BinStr:=Bin(StrToInt(Copy(WorkStr,1,Pos('_',WorkStr)-1)));
              // Формируем имена левой и правой части без указания размера в блоках
              LeftName:=IntToStr(BinToDec(BinStr+'0'))+'_0_'+IntToStr(Processes[NumberOfProcess].Level)+'.'+IntToStr(NumberOfProcess)+'pr';
              RightName:=IntToStr(BinToDec(BinStr+'1'))+'_1_'+IntToStr(Processes[NumberOfProcess].Level)+'.'+IntToStr(NumberOfProcess)+'pr';
              // Разбиваем на две части найденный файл
              repeat
                // Цикл ожидания разрешения
              until WorkFlag;
              WorkFlag:=false;
              SeparateRes:=FileSeparate(sr.name,LeftName,RightName,
                                        StrToInt(Copy(sr.name,1,Pos('_',sr.name)-1)),CountLeft,CountRight);
              WorkFlag:=true;
              if SeparateRes then
                begin
                  // Файл успешно разделен на две части - переименовываем их добавляя размер в начало имени
                  repeat
                    // Цикл ожидания разрешения
                  until WorkFlag;
                  WorkFlag:=false;
                  RenameFile(LeftName,IntToStr(CountLeft)+'_'+LeftName);
                  WorkFlag:=true;
                  repeat
                    // Цикл ожидания разрешения
                  until WorkFlag;
                  WorkFlag:=false;
                  RenameFile(RightName,IntToStr(CountRight)+'_'+RightName);
                  WorkFlag:=true;
                  MainFilesCount:=MainFilesCount+1;
                end
              else
                begin
                  // Получили один отсортированный файл - переименовываем его в формат [Уникальный номер].res
                  WorkStr:=IntToStr(BinToDec(BinStr+'0'))+'.re';
                  repeat
                    // Цикл ожидания разрешения
                  until WorkFlag;
                  WorkFlag:=false;
                  RenameFile(LeftName,WorkStr);
                  WorkFlag:=true;
                  MainFilesCount:=MainFilesCount-1;
                  Processes[NumberOfProcess].Progress:=Processes[NumberOfProcess].Progress+CountLeft;
                end;
              // Удаляем обработанный исходный файл
              repeat
                // Цикл ожидания разрешения
              until WorkFlag;
              WorkFlag:=false;
              DeleteFile(sr.name);
              WorkFlag:=true;
            until FindNext(sr) <> 0;
            FindClose(sr);
          end;
      until MainFilesCount=0;
      // Задача выполнена - данные процесса отсортированы, отключаем процесс в таймере главной формы
      Processes[NumberOfProcess].Flag:=false;
    end;
end;

end.
