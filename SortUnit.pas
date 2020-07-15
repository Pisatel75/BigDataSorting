unit SortUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Samples.Gauges, TThreadUnit, GlobalVar,
  Vcl.ExtCtrls;

type
  TForm1 = class(TForm)
    Gauge1: TGauge;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Gauge2: TGauge;
    Gauge3: TGauge;
    Gauge4: TGauge;
    Button1: TButton;
    Gauge5: TGauge;
    Timer1: TTimer;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    procedure Button1Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  Process1,Process2,Process3,Process4:DecompProcess;

implementation

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
var
  TextData,ZeroData,MainWork,ResultFile:TextFile;
  i,j,MainFilesCount,MaxBinLength:Integer;
  CountLeft,CountRight:Int64;
  ProccessNumber:Byte;
  Letter:AnsiChar;
  WorkStr,LeftName,RightName,BinStr:String;
  FlagCRLF,ZeroFlag:Boolean;
  sr:TSearchRec;
  ResNames:array of ResNamesRec;
begin
  // Обнуляем счетчики
  for i:=1 to 4 do
    begin
      Processes[i].Size:=0;
      Processes[i].Flag:=false;
      Processes[i].Progress:=0;
      Processes[i].Level:=0;
      Processes[i].ID:=0;
      Processes[i].Free:=true;
    end;
  // Инициализируем переменные
  FlagCRLF:=false;
  TotalCount:=0;
  TotalReady:=0;
  // Сбрасываем лейблы
  Label5.Caption:='Отсортировано 0 из 0 строк';
  Label6.Caption:='Отсортировано 0 из 0 строк';
  Label7.Caption:='Отсортировано 0 из 0 строк';
  Label8.Caption:='Отсортировано 0 из 0 строк';
  Label9.Caption:='Всего отсортировано 0 из 0 строк';
  // Сбрасываем прогрессбары
  Gauge1.Progress:=0;
  Gauge2.Progress:=0;
  Gauge3.Progress:=0;
  Gauge4.Progress:=0;
  Gauge5.Progress:=0;
  // Читаем исходный файл посимвольно (первый прогон для оценки и отделения "нулевых" строк)
  AssignFile(TextData,InitialDataFile);
  Reset(TextData);
  CurrentLevel:=0;
  // Имя файла: [Размер в блоках]_[Уникальный номер]_[0 или 1]_[Уровень иерархии].dat
  AssignFile(MainWork,'0_1_0_0.dat');
  Rewrite(MainWork);
  ZeroCount:=0;
  ZeroFlag:=true;
  Repeat
    // Читаем текущий символ
    Read(TextData,Letter);
    if Letter=Chr(13) then
      begin
        FlagCRLF:=true;
      end
    else
      begin
        if (Letter=Chr(10)) and FlagCRLF then
          begin
            // Комбинация CRLF
            TotalCount:=TotalCount+1;
            // Проверяем пустую строку
            if ZeroFlag then
              begin
                ZeroCount:=ZeroCount+1;
              end
            else
              begin
                Write(MainWork,Chr(13)+Chr(10));
              end;
            ZeroFlag:=true;
          end
        else
          begin
            // Комбинация CRLF отсутствует
            if FlagCRLF then
              begin
                // В данном случае Chr(13) - это часть сортируемой строки
                Write(MainWork,Chr(13)+Letter);
              end
            else
              begin
                // Комбинация CRLF не включается в состав строки
                Write(MainWork,Letter);
              end;
            ZeroFlag:=false;
          end;
        FlagCRLF:=false;
      end;
  Until EoF(TextData);
  CloseFile(TextData);
  CloseFile(MainWork);
  TotalReady:=ZeroCount;
  Label9.Caption:='Всего отсортировано '+IntToStr(TotalReady)+' из '+IntToStr(TotalCount)+' строк';
  Gauge5.Progress:=Round(TotalReady/TotalCount*100);
  // Сохраняем количество найденных пустых строк в отдельный файл
  AssignFile(ZeroData,'zero.txt');
  Rewrite(ZeroData);
  WriteLn(ZeroData,IntToStr(ZeroCount));
  CloseFile(ZeroData);
  MainFilesCount:=1;
  RenameFile('0_1_0_0.dat',IntToStr(TotalCount-ZeroCount)+'_1_0_0.dat');
  // Разбиваем очищенный файл пока не получим 4 части для расчетов в 4-х параллельных процессах
  repeat
    CurrentLevel:=CurrentLevel+1;
    // Читаем первое попавшееся имя файла
    if FindFirst('*_'+IntToStr(CurrentLevel-1)+'.dat', faAnyFile, sr) = 0 then
      begin
        repeat
          // Разбираем имя найденного файла для классификации результатов его обработки
          WorkStr:=sr.name;
          // Удаляем размер
          Delete(WorkStr,1,Pos('_',WorkStr));
          // Вынимаем уникальный десятичный номер и преобразуем его в двоичную строку
          BinStr:=Bin(StrToInt(Copy(WorkStr,1,Pos('_',WorkStr)-1)));
          // Формируем имена левой и правой части без указания размера в блоках
          LeftName:=IntToStr(BinToDec(BinStr+'0'))+'_0_'+IntToStr(CurrentLevel)+'.dat';
          RightName:=IntToStr(BinToDec(BinStr+'1'))+'_1_'+IntToStr(CurrentLevel)+'.dat';
          // Разбиваем на две части найденный файл
          if FileSeparate(sr.name,LeftName,RightName,
                          StrToInt(Copy(sr.name,1,Pos('_',sr.name)-1)),CountLeft,CountRight) then
            begin
              // Файл успешно разделен на две части - переименовываем их добавляя размер в начало имени
              RenameFile(LeftName,IntToStr(CountLeft)+'_'+LeftName);
              RenameFile(RightName,IntToStr(CountRight)+'_'+RightName);
              MainFilesCount:=MainFilesCount+1;
            end
          else
            begin
              // Получили один отсортированный файл - переименовываем его в формат [Уникальный номер].re
              WorkStr:=IntToStr(BinToDec(BinStr+'0'))+'.re';
              RenameFile(LeftName,WorkStr);
              MainFilesCount:=MainFilesCount-1;
              TotalReady:=TotalReady+CountLeft;
              Label9.Caption:='Всего отсортировано '+IntToStr(TotalReady)+' из '+IntToStr(TotalCount);
              Gauge5.Progress:=Round(TotalReady/TotalCount*100);
            end;
          // Удаляем обработанный исходный файл
          DeleteFile(sr.name);
        until FindNext(sr) <> 0;
        FindClose(sr);
      end;
  until ((MainFilesCount=4) or (MainFilesCount=0));
  if MainFilesCount=4 then
    begin
      // Получили четыре файла для сортировки *.dat - переименовываем их, запускаем параллельные процессы и таймер
      if FindFirst('*.dat', faAnyFile, sr) = 0 then
        begin
          ProccessNumber:=1;
          CurrentLevel:=CurrentLevel+1;
          repeat
            // Переименовываем текущий файл в формат [Размер]_[Уникальный номер]_[0/1]_[Уровень].[Номер процесса]pr
            WorkStr:=sr.name;
            // Удаляем размер
            LeftName:=Copy(WorkStr,1,Pos('_',WorkStr)-1);
            Delete(WorkStr,1,Pos('_',WorkStr));
            // Вынимаем уникальный номер
            RightName:=Copy(WorkStr,1,Pos('_',WorkStr)-1);
            // Переименовываем файл
            RenameFile(sr.name,LeftName+'_'+RightName+'_0_'+IntToStr(CurrentLevel)+'.'+IntToStr(ProccessNumber)+'pr');
            Processes[ProccessNumber].Size:=StrToInt(LeftName);
            ProccessNumber:=ProccessNumber+1;
          until FindNext(sr) <> 0;
          FindClose(sr);
        end;
      WorkFlag:=true;
      // Создаём и запускаем четыре процесса
      Processes[1].Flag:=true;
      Processes[1].Free:=false;
      Label5.Caption:='Отсортировано 0 из '+IntToStr(Processes[1].Size)+' строк';
      Processes[1].Level:=CurrentLevel;
      Process1:=DecompProcess.Create(false);
      Process1.Priority:=tpNormal;
      Sleep(100);
      // +++++++++++++++++++++++++++++++++++
      Processes[2].Flag:=true;
      Processes[2].Free:=false;
      Label6.Caption:='Отсортировано 0 из '+IntToStr(Processes[2].Size)+' строк';
      Processes[2].Level:=CurrentLevel;
      Process2:=DecompProcess.Create(false);
      Process2.Priority:=tpNormal;
      Sleep(100);
      // +++++++++++++++++++++++++++++++++++
      Processes[3].Flag:=true;
      Processes[3].Free:=false;
      Label7.Caption:='Отсортировано 0 из '+IntToStr(Processes[3].Size)+' строк';
      Processes[3].Level:=CurrentLevel;
      Process3:=DecompProcess.Create(false);
      Process3.Priority:=tpNormal;
      Sleep(100);
      // +++++++++++++++++++++++++++++++++++
      Processes[4].Flag:=true;
      Processes[4].Free:=false;
      Label8.Caption:='Отсортировано 0 из '+IntToStr(Processes[4].Size)+' строк';
      Processes[4].Level:=CurrentLevel;
      Process4:=DecompProcess.Create(false);
      Process4.Priority:=tpNormal;
      Sleep(100);
      // Включаем таймер
      Timer1.Enabled:=true;
    end
  else
    begin
      // Получили отсортированные файлы для склейки *.re - формируем их сортированный список и соединяем в файл result.txt
      ResultConstuct;
      Close;
    end;
end;

// Таймер состояния процессов
procedure TForm1.Timer1Timer(Sender: TObject);
var
  i,ReadyCount:Integer;
  FlagEnd:Boolean;
begin
  Timer1.Enabled:=false;
  FlagEnd:=true;
  for i:=1 to 4 do
    begin
      // Сканируем состояние процессов
      if (not Processes[i].Flag) and (not Processes[i].Free) then
        begin
          // Отключаем текущий процесс и обновляем его статистику
          case i of
            1:
              begin
                Process1.Terminate;
                Processes[i].Free:=true;
                Label5.Caption:='Отсортировано '+IntToStr(Processes[i].Size)+' из '+IntToStr(Processes[i].Size)+' строк';
                Gauge1.Progress:=100;
              end;
            2: 
              begin
                Process2.Terminate;
                Processes[i].Free:=true;
                Label6.Caption:='Отсортировано '+IntToStr(Processes[i].Size)+' из '+IntToStr(Processes[i].Size)+' строк';
                Gauge2.Progress:=100;
              end;
            3:
              begin
                Process3.Terminate;
                Processes[i].Free:=true;
                Label7.Caption:='Отсортировано '+IntToStr(Processes[i].Size)+' из '+IntToStr(Processes[i].Size)+' строк';
                Gauge3.Progress:=100;
              end;
            4: 
              begin
                Process4.Terminate;
                Processes[i].Free:=true;
                Label8.Caption:='Отсортировано '+IntToStr(Processes[i].Size)+' из '+IntToStr(Processes[i].Size)+' строк';
                Gauge4.Progress:=100;
              end;
          end;
        end
      else
        begin
          if Processes[i].Flag then
            begin
              // Есть незавершенные процессы, обновляем их статистику
              FlagEnd:=false;
              case i of
              1:
                begin
                  Label5.Caption:='Отсортировано '+IntToStr(Processes[i].Progress)+' из '+IntToStr(Processes[i].Size)+' строк';
                  Gauge1.Progress:=Round(Processes[i].Progress/Processes[i].Size*100);
                end;
              2: 
                begin
                  Label6.Caption:='Отсортировано '+IntToStr(Processes[i].Progress)+' из '+IntToStr(Processes[i].Size)+' строк';
                  Gauge2.Progress:=Round(Processes[i].Progress/Processes[i].Size*100);
                end;
              3: 
                begin
                  Label7.Caption:='Отсортировано '+IntToStr(Processes[i].Progress)+' из '+IntToStr(Processes[i].Size)+' строк';
                  Gauge3.Progress:=Round(Processes[i].Progress/Processes[i].Size*100);
                end;
              4: 
                begin
                  Label8.Caption:='Отсортировано '+IntToStr(Processes[i].Progress)+' из '+IntToStr(Processes[i].Size)+' строк';
                  Gauge4.Progress:=Round(Processes[i].Progress/Processes[i].Size*100);
                end;
              end;
            end;
        end;
      ReadyCount:=TotalReady+Processes[1].Progress+Processes[2].Progress+Processes[3].Progress+Processes[4].Progress;
      Label9.Caption:='Всего отсортировано '+IntToStr(ReadyCount)+' из '+IntToStr(TotalCount);
      Gauge5.Progress:=Round(ReadyCount/TotalCount*100);
    end;
  if not FlagEnd then
    begin
      // Продолжаем сканировать процессы
      ReadyCount:=TotalReady+Processes[1].Progress+Processes[2].Progress+Processes[3].Progress+Processes[4].Progress;
      Label9.Caption:='Всего отсортировано '+IntToStr(ReadyCount)+' из '+IntToStr(TotalCount);
      Gauge5.Progress:=Round(ReadyCount/TotalCount*100);
      Timer1.Enabled:=true;
    end
  else
    begin
      // Все процессы завершены, осуществляем сборку результата сортировки в файле result.txt и выводим сообщение
      Label9.Caption:='Всего отсортировано '+IntToStr(TotalCount)+' из '+IntToStr(TotalCount)+' строк';
      Gauge5.Progress:=100;
      ResultConstuct;
      Close;
    end;
end;

end.
