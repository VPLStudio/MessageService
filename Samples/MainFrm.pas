unit MainFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,System.JSON.Types, System.JSON.Serializers,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,VPL.Messaging, FMX.StdCtrls,System.TypInfo,VPL.IPC,
  FMX.EditBox, FMX.NumberBox, FMX.Controls.Presentation, FMX.Edit,System.NetEncoding,System.JSON,System.Rtti,System.IOUtils,
  FMX.Memo.Types, FMX.ScrollBox, FMX.Memo, IdCustomTCPServer, IdTCPServer, IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient, IdContext, IdUDPServer,
  IdGlobal, IdSocketHandle, IdUDPBase, IdUDPClient, FMX.ListBox;

const
  CM_StringMessage    = CM_USER + 0;
  CM_TupleMessage     = CM_USER + 1;
  CM_RemoteMessage    = CM_USER + 2;
  CM_BoolMessage      = CM_USER + 3;
  CM_ArgumentMessage  = CM_USER + 4;
  CM_Broadcast        = CM_USER + 5;

type

  TDemoRec = record
    A: Boolean;
    B: Int16;
    C: String;
    E: Single;
  end;

  TMainForm = class(TForm)
    SendButton: TButton;
    MessageMemo: TMemo;
    IPCBtn: TButton;
    StringMessageBtn: TButton;
    Label1: TLabel;
    Button1: TButton;
    ArgumentMessageBtn: TButton;
    TupleMessageBtn: TButton;
    ModeComboBox: TComboBox;
    BroadcastBtn: TButton;
    GroupBox1: TGroupBox;
    Label2: TLabel;
    IdUDPClient1: TIdUDPClient;
    IdUDPServer1: TIdUDPServer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure SendButtonClick(Sender: TObject);
    procedure IPCBtnClick(Sender: TObject);
    procedure StringMessageBtnClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure ArgumentMessageBtnClick(Sender: TObject);
    procedure TupleMessageBtnClick(Sender: TObject);
    procedure BroadcastBtnClick(Sender: TObject);
  private
    { Private declarations }

  public
    { Public declarations }
    procedure CMRemote(var Message: TVPLMessage<TObject,TIPCValue,TIPCValue>); message CM_RemoteMessage;
    procedure CMStringMessage(var Message: TVPLMessage<TObject,String>); message CM_StringMessage;
    procedure CMBoolMessage(var Message: TVPLMessage<TForm,Boolean>); message CM_BoolMessage;
    procedure CMArgumentMessage(var Message: TVPLMessage<TForm,Integer,Integer>); message CM_ArgumentMessage;
    procedure CMTupleMessage(var Message: TVPLMessage<TForm,TArray<TVarRec>,TArray<TVarRec>>); message CM_TupleMessage;
    procedure CMBroadcast(var Message: TVPLMessage<TForm,TIPCValue>); message CM_Broadcast;

  end;

var
  MainForm: TMainForm;

implementation

{$R *.fmx}

{ TMainForm }

procedure TMainForm.IPCBtnClick(Sender: TObject);
begin
  if not IPC.Actived then
  begin
    if IPC.Start(TIPCMode(ModeComboBox.ItemIndex)) then
    begin
      if IPC.IsMainServer then
        Self.Caption := 'Message Service Server'
      else
        Self.Caption := 'Message Service Client';
      IPCBtn.Text := 'Disable IPC';
      ModeComboBox.Enabled := False;
    end;
  end
  else
  begin
    IPC.Stop;
    ModeComboBox.Enabled := True;
    IPCBtn.Text := 'Enable IPC';
  end;
end;

procedure TMainForm.BroadcastBtnClick(Sender: TObject);
begin
  IPC.SendMessage<String>(CM_Broadcast,'Broadcast Message',True);
end;

procedure TMainForm.Button1Click(Sender: TObject);
var
  Ret: Boolean;
begin
  Ret :=  MessageService.GetMessage<Boolean>(Self,CM_BoolMessage);
  if Ret then
    MessageMemo.Lines.Add('BoolMessage=True')
  else
    MessageMemo.Lines.Add('BoolMessage=Flase')
end;

procedure TMainForm.CMArgumentMessage(var Message: TVPLMessage<TForm, Integer, Integer>);
begin
  Message.Param2 := Message.Param1 + 1;
end;

procedure TMainForm.CMRemote(var Message: TVPLMessage<TObject, TIPCValue,TIPCValue>);
begin
  if IPC.IsMainServer then
    Message.Param2 := TIPCValue.From(System.IOUtils.TPath.GetFileNameWithoutExtension(ParamStr(0))+' From Server')
  else
    Message.Param2 := TIPCValue.From(System.IOUtils.TPath.GetFileNameWithoutExtension(ParamStr(0))+' From Client')
end;

procedure TMainForm.ArgumentMessageBtnClick(Sender: TObject);
var
  Param: Integer;
  Ret: Integer;
begin
  Param := 2023;
  Ret := MessageService.GetMessage<Integer,Integer>(Self,CM_ArgumentMessage,Param);
  MessageMemo.Lines.Add(Format('ArgumentMessage(Arg=%d,Ret=%d)',[Param,Ret]));
end;

procedure TMainForm.CMBoolMessage(var Message: TVPLMessage<TForm, Boolean>);
begin
  Message.Param := True;
end;

procedure TMainForm.CMBroadcast(var Message: TVPLMessage<TForm, TIPCValue>);
begin
  MessageMemo.Lines.Add(Message.Param.AsString);
end;

procedure TMainForm.CMStringMessage(var Message: TVPLMessage<TObject, String>);
begin
  MessageMemo.Lines.Add(Message.Param);
end;

procedure TMainForm.CMTupleMessage(var Message: TVPLMessage<TForm, TArray<TVarRec>, TArray<TVarRec>>);
begin
  MessageMemo.Lines.Add(Format('Recv Tuple: Str=%s,Int=%d',[Message.Param1[0].ToString,Message.Param1[1].vInteger]));
  Message.Param2 := CreateTuple([Message.Param1[0].ToString+'Ret',Message.Param1[1].vInteger+1]);
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  ReportMemoryLeaksOnShutdown := True;
  MessageService.AutoSubscribe(Self);
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  MessageService.Unsubscribe(Self);
end;

procedure TMainForm.SendButtonClick(Sender: TObject);
begin
  MessageMemo.Lines.Add(IPC.GetMessage<String,String>(CM_RemoteMessage,'Hello'));
end;

procedure TMainForm.StringMessageBtnClick(Sender: TObject);
begin
  MessageService.SendMessage<String>(Self,CM_StringMessage,'String Message');
end;

procedure TMainForm.TupleMessageBtnClick(Sender: TObject);
var
  Ret: TArray<TVarRec>;
begin
  Ret := MessageService.GetMessage<TArray<TVarRec>>(Self,CM_TupleMessage,['Dudo',2000]);
  MessageMemo.Lines.Add(Format('Ret Tuple: Str=%s,Int=%d',[Ret[0].ToString,Ret[1].vInteger]));
end;

end.
