 (*
  *           MessageService - Message service for Delphi
  *
  * The MIT License (MIT)
  * Copyright (c) 2023 Dudo
  *
  *
  * Permission is hereby granted, free of charge, to any person
  * obtaining a copy of this software and associated documentation
  * files (the "Software"), to deal in the Software without restriction,
  * including without limitation the rights to use, copy, modify,
  * merge, publish, distribute, sublicense, and/or sell copies of the Software,
  * and to permit persons to whom the Software is furnished to do so,
  * subject to the following conditions:
  *
  * The above copyright notice and this permission notice shall
  * be included in all copies or substantial portions of the Software.
  *
  * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
  * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
  * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
  * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
  * DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
  * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH
  * THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
  *
  *)
unit VPL.Messaging;

interface
uses
  System.Types, System.Classes,System.SysUtils,System.TypInfo,
  System.Generics.Collections,System.Threading,System.SyncObjs;

const
  CM_SYSTEM   = $1700;//MM_USER;  // MM_USER = $1700; ref from FMX.Controls.Model
  CM_USER     = CM_SYSTEM+100;  // <100  reserved

  CM_MAX      = $C000;    //>= $C000 Run error!
type
  TMessageID = Word; // ref FMX.Presentation.Messages

  MessageException = class(Exception);

  TVPLListener = reference to procedure(var Message);
  TVPLListenerMethod = procedure (var Message) of object;

  TVarRecHelper = record helper for TVarRec
  public
    function ToString: String; inline;
  end;

  TVPLTuple = TArray<TVarRec>;

  TVPLMessage<S: class> = record
    MsgID: TMessageID;
    Sender: S;
  public
    constructor Create(const ASender: S;const AMsgID: TMessageID);
  end;

  TVPLMessage<S: class;P> = record
    MsgID: TMessageID;
    Sender: S;
    Param: P;
  public
    constructor Create(const ASender: S;const AMsgID: TMessageID;const AParam: P);
  end;

  TVPLMessage<S: class;P1;P2> = record
    MsgID: TMessageID;
    Sender: S;
    Param1: P1;
    Param2: P2;
  public
    constructor Create(const ASender: S;const AMsgID: TMessageID;const AParam1: P1;const AParam2: P2);
  end;

  TSubscriberData = record
    Sender: TObject;
    Subscriber: TObject;
    Listener: TVPLListener;
    ListenerMethod: TVPLListenerMethod;
  public
    constructor Create(const ASubscriber,ASender: TObject;AListener: TVPLListener); overload;
    constructor Create(const ASubscriber,ASender: TObject;AListenerMethod: TVPLListenerMethod); overload;
  end;

  TVPLMessageService = class;

  TMessageSubscribers = class
  private
    FLock: TObject;
    FList: TList<TSubscriberData>;
    FMessageService: TVPLMessageService;
  protected
    procedure Lock; inline;
    procedure UnLock; inline;
    procedure AddListener(const Subscriber,Sender: TObject;const Listener: TVPLListener); overload; inline;
    procedure AddListener(const Subscriber,Sender: TObject;const ListenerMethod: TVPLListenerMethod); overload; inline;
    procedure SetSender(const Subscriber,Sender: TObject);
    procedure RemoveSubscriber(const Subscriber: TObject); overload;
    procedure RemoveListener(const Listener: TVPLListener); overload;
    procedure RemoveListener(const ListenerMethod: TVPLListenerMethod); overload;
  public
    constructor Create(MessageService: TVPLMessageService); virtual;
    destructor Destroy; override;
    procedure SetPriority(const Subscriber: TObject;const Priority: Integer);
    procedure SendMessage(const Sender: TObject;const MessageID: TMessageID); overload;
    procedure SendMessage(const Sender: TObject;const MessageID: TMessageID;const Param: TObject); overload; inline;
    procedure SendMessage(const Sender: TObject;const MessageID: TMessageID;const Param: TObject;const ADispose: Boolean); overload;
    procedure SendMessage(const Sender: TObject;const MessageID: TMessageID;const Params: array of const); overload;
    procedure SendMessage(const Sender: TObject;const MessageID: TMessageID;const Params: TArray<TVarRec>); overload;
    procedure SendMessage<P>(const Sender: TObject;const MessageID: TMessageID; const Param: P); overload;
    procedure SendMessage<P1,P2>(const Sender: TObject;const MessageID: TMessageID; const Param1: P1;const Param2: P2); overload;
    procedure SendMessageWithResult<V>(const Sender: TObject;const MessageID: TMessageID; var Value: V); overload;
    procedure SendMessageWithResult<P,V>(const Sender: TObject;const MessageID: TMessageID; const Param: P;var Value: V); overload;
    function GetMessage<V>(const Sender: TObject;const MessageID: TMessageID): V; overload; inline;
    function GetMessage<P,V>(const Sender: TObject;const MessageID: TMessageID; const Param: P): V; overload;inline;
  end;

  TMsgIDMap = class
  private
    FLock: TObject;
    FMinID: Integer;
    FMaxID: Integer;
    FMessageService: TVPLMessageService;
    FSubscribers: TArray<TMessageSubscribers>;
    function GetListenerData(const Index: TMessageID): TMessageSubscribers; inline;
  protected
    procedure Lock; inline;
    procedure UnLock; inline;
    procedure FreeListenerList(const MessageID: TMessageID);
    function SetListenerList(const MessageID: TMessageID): TMessageSubscribers;
  public
    constructor Create(MessageService: TVPLMessageService); reintroduce;
    destructor Destroy; override;
    procedure Subscribe(const Subscriber: TObject;const Sender: TObject;const MessageID: TMessageID;const Listener: TVPLListener); overload;
    procedure Subscribe(const Subscriber: TObject;const Sender: TObject;const MessageID: TMessageID;const ListenerMethod: TVPLListenerMethod); overload;
    procedure Subscribe(const Subscriber: TObject;const Sender: TObject;const MessageID: TMessageID); overload;
    procedure SetPriority(const Subscriber: TObject;const MessageID: TMessageID;const Priority: Integer);
    procedure Unsubscribe(const MessageID: TMessageID); overload;
    procedure Unsubscribe(const Subscriber: TObject); overload;
    procedure Unsubscribe(const Listener: TVPLListener); overload;
    procedure Unsubscribe(const ListenerMethod: TVPLListenerMethod); overload;
    procedure Unsubscribe(const Subscriber: TObject;const MessageID: TMessageID); overload;
    property Items[const Index: TMessageID]: TMessageSubscribers read GetListenerData; default;
    property Subscribers: TArray<TMessageSubscribers> read FSubscribers;
  end;

  TMessageTask = class;

  TVPLMessageService = class
  private
    FLock: TObject;
    FMsgIDMap: TMsgIDMap;
    FProcessing: Integer;
    FMessageTask: TMessageTask;
    FMessages: TDictionary<TMessageID,TMessageID>;
    function IsRegistered(const MessageID: SmallInt): Boolean;
    { Global instance }
    class var FMessageService: TVPLMessageService;
    class function GetMessageService: TVPLMessageService; static;
  protected
    procedure Lock; inline;
    procedure UnLock; inline;
    procedure IncProcessing; inline;
    procedure DecProcessing; inline;
  public
    constructor Create;
    destructor Destroy; override;
    class destructor UnInitialize;
    procedure RegisterMessage(const MessageID: TMessageID); overload;
    procedure RegisterMessage(const Messages: array of TMessageID); overload;
    procedure UnRegisterMessage(const MessageID: TMessageID); overload;
    procedure UnRegisterMessage(const Messages: array of TMessageID); overload;
    procedure AutoSubscribe(const Subscriber: TObject); overload;inline;
    procedure AutoSubscribe(const Subscriber: TObject;const Sender: TObject); overload;
    procedure Subscribe(const MessageID: TMessageID;const Listener: TVPLListener); overload; inline;
    procedure Subscribe(const Sender: TObject;const MessageID: TMessageID;const Listener: TVPLListener); overload; inline;
    procedure Subscribe(const Subscriber: TObject;const MessageID: TMessageID); overload;
    procedure Subscribe(const Subscriber: TObject;const Sender: TObject;const MessageID: TMessageID); overload;
    procedure Subscribe(const MessageID: TMessageID;const ListenerMethod: TVPLListenerMethod); overload;
    procedure Subscribe(const Sender: TObject;const MessageID: TMessageID;const ListenerMethod: TVPLListenerMethod); overload;
    procedure SubscribePriority(const Subscriber: TObject;const MessageID: TMessageID;const Priority: Integer=0);
    procedure Unsubscribe(const MessageID: TMessageID); overload;  inline;
    procedure Unsubscribe(const Subscriber: TObject); overload; inline;
    procedure Unsubscribe(const Listener: TVPLListener); overload; inline;
    procedure Unsubscribe(const ListenerMethod: TVPLListenerMethod); overload; inline;
    procedure Unsubscribe(const Subscriber: TObject;const MessageID: TMessageID); overload; inline;
    procedure SendMessage(const Sender: TObject;const MessageID: TMessageID); overload;
    procedure SendMessage(const Sender: TObject;const MessageID: TMessageID;const Params: TObject;const ADispose: Boolean=True); overload;
    procedure SendMessage(const Sender: TObject;const MessageID: TMessageID;const Params: array of const); overload;
    procedure SendMessage(const Sender: TObject;const MessageID: TMessageID;const Params: TArray<TVarRec>); overload;
    procedure SendMessage<P>(const Sender: TObject;const MessageID: TMessageID; const Param: P); overload;
    procedure SendMessage<P1,P2>(const Sender: TObject;const MessageID: TMessageID; const Param1: P1;const Param2: P2); overload;
    function GetMessage<V>(const Sender: TObject;const MessageID: TMessageID): V; overload; inline;
    function GetMessage<P,V>(const Sender: TObject;const MessageID: TMessageID; const Param: P): V; overload; inline;
    function GetMessage<V>(const Sender: TObject;const MessageID: TMessageID;const Params: array of const): V; overload;
    procedure SendMessageWithResult<V>(const Sender: TObject;const MessageID: TMessageID; var Value: V); overload;
    procedure SendMessageWithResult<P,V>(const Sender: TObject;const MessageID: TMessageID; const Param: P;var Value: V); overload;
    procedure SendMessageWithResult<V>(const Sender: TObject;const MessageID: TMessageID;const Params: array of const;var Value: V); overload;
    procedure PostMessage(const Sender: TObject;const MessageID: TMessageID;const Synchronize: Boolean=False); overload;
    procedure PostMessage(const Sender: TObject;const MessageID: TMessageID;const Message: TObject;const Synchronize: Boolean=False;const ADispose: Boolean=True); overload;
    procedure PostMessage(const Sender: TObject;const MessageID: TMessageID;const Params: array of const;const Synchronize: Boolean=False); overload;
    property MessageTask: TMessageTask read FMessageTask;
    class property DefaultMessageService: TVPLMessageService read GetMessageService;
  end;

  TTaskData = class
  private
    FSender: TObject;
    FSynchronize: Boolean;
    FMessageID: TMessageID;
  protected
    procedure DoSendMessage(const MessageService: TVPLMessageService); virtual;
  public
    constructor Create(Sender: TObject;const MessageID: TMessageID;const Synchronize: Boolean); virtual;
    procedure SendMessage(const MessageService: TVPLMessageService);
  end;

  TObjectTaskData = class(TTaskData)
  private
    FParam: TObject;
    FDispose: Boolean;
  protected
    procedure DoSendMessage(const MessageService: TVPLMessageService); override;
  public
    constructor Create(Sender: TObject;const MessageID: TMessageID;const Param: TObject;const ADispose: Boolean;const Synchronize: Boolean); reintroduce;
    destructor Destroy; override;
  end;

  TTupleTaskData = class(TTaskData)
  private
    FParams: TVPLTuple;
  protected
    procedure DoSendMessage(const MessageService: TVPLMessageService); override;
  public
    constructor Create(Sender: TObject;const MessageID: TMessageID;const Params: TVPLTuple;const Synchronize: Boolean); reintroduce;
    destructor Destroy; override;
  end;

  TMessageTask = class
  private
    FTask: ITask;
    FLock: TObject;
    FTerminated: Boolean;
    FMessageQueue: TQueue<TTaskData>;
    FMessageService: TVPLMessageService;
    function CreateTask: ITask;
    procedure AddQueue(const Sender: TObject;const MessageID: TMessageID;const Synchronize: Boolean);
    procedure AddObjectQueue(const Sender: TObject;const MessageID: TMessageID;const Param: TObject;const Synchronize,ADispose: Boolean);
    procedure AddTupleQueue(const Sender: TObject;const MessageID: TMessageID;const Params: TVPLTuple;const Synchronize: Boolean);
  protected
    procedure Start;
    procedure Lock; inline;
    procedure UnLock; inline;
  public
    constructor Create(MessageService: TVPLMessageService); virtual;
    destructor Destroy; override;
    procedure Terminate;
    procedure PostMessage(const Sender: TObject;const MessageID: TMessageID;const Synchronize: Boolean); overload; inline;
    procedure PostMessage(const Sender: TObject;const MessageID: TMessageID;const Param: TObject;const Synchronize,ADispose: Boolean); overload; inline;
    procedure PostMessage(const Sender: TObject;const MessageID: TMessageID;const Params: array of const;const Synchronize: Boolean=False); overload;
    procedure PostMessage(const Sender: TObject;const MessageID: TMessageID;const Params: TVPLTuple;const Synchronize: Boolean=False); overload; inline;
    property MessageQueue: TQueue<TTaskData> read FMessageQueue;
  end;

  TMeeeagePair = class
  private
    FPairCount: Integer;
    FSupervisor: TObject;
    FMessageService: TVPLMessageService;
  public
    constructor Create; overload; virtual;
    constructor Create(Supervisor: TObject); overload; virtual;
    destructor Destroy; override;
    procedure Pairing(const Pair: TObject);
    procedure UnPairing(const Pair: TObject);
    procedure SubscribeSupervisor;
    procedure RegisterMessage(const MessageID: TMessageID); overload; inline;
    procedure RegisterMessage(const Messages: array of TMessageID); overload;
    procedure UnRegisterMessage(const MessageID: TMessageID); overload; inline;
    procedure UnRegisterMessage(const Messages: array of TMessageID); overload;
    procedure SendMessage(const Sender: TObject;const MessageID: TMessageID); overload; inline;
    procedure SendMessage(const Sender: TObject;const MessageID: TMessageID;const Param: TObject); overload; inline;
    procedure SendMessage(const Sender: TObject;const MessageID: TMessageID;const Param: TObject;const ADispose: Boolean); overload; inline;
    procedure SendMessage(const Sender: TObject;const MessageID: TMessageID;const Params: array of const); overload;
    procedure SendMessage(const Sender: TObject;const MessageID: TMessageID;const Params: TVPLTuple); overload;
    procedure SendMessage<P>(const Sender: TObject;const MessageID: TMessageID; const Param: P); overload; inline;
    procedure SendMessage<P1,P2>(const Sender: TObject;const MessageID: TMessageID; const Param1: P1;const Param2: P2); overload; inline;
    function GetMessage<V>(const Sender: TObject;const MessageID: TMessageID): V; overload; inline;
    function GetMessage<P,V>(const Sender: TObject;const MessageID: TMessageID; const Param: P): V; overload; inline;
    function GetMessage<V>(const Sender: TObject;const MessageID: TMessageID;const Params: array of const): V; overload;
    procedure SendMessageWithResult<V>(const Sender: TObject;const MessageID: TMessageID; var Value: V); overload; inline;
    procedure SendMessageWithResult<P,V>(const Sender: TObject;const MessageID: TMessageID; const Param: P;var Value: V); overload; inline;
    procedure SendMessageWithResult<V>(const Sender: TObject;const MessageID: TMessageID;const Params: array of const;var Value: V); overload;
    procedure PostMessage(const Sender: TObject;const MessageID: TMessageID;const Synchronize: Boolean=False); overload; inline;
    procedure PostMessage(const Sender: TObject;const MessageID: TMessageID;const Param: TObject;const Synchronize: Boolean=False;const ADispose: Boolean=True); overload; inline;
    procedure PostMessage(const Sender: TObject;const MessageID: TMessageID;const Params: array of const;const Synchronize: Boolean=False); overload;
    procedure PostMessage(const Sender: TObject;const MessageID: TMessageID;const Params: TVPLTuple;const Synchronize: Boolean=False); overload; inline;
    property MessageService: TVPLMessageService read FMessageService;
    property Supervisor: TObject read FSupervisor;
    property PairCount: Integer read FPairCount;
  end;

var
  MessageService: TVPLMessageService;

function CreateTuple(const Values: array of const): TArray<TVarRec>;

implementation

function CreateTuple(const Values: array of const): TArray<TVarRec>;
begin
  SetLength(Result,Length(Values));
  for var I := Low(Values) to High(Values) do
    Result[I] := Values[I];
end;

procedure TVPLMessageService.AutoSubscribe(const Subscriber, Sender: TObject);
type
  TDynaMethodTable = record
    Count: Word;
    Selectors: array[0..9999999] of SmallInt;
  end;
  PDynaMethodTable = ^TDynaMethodTable;
var
  I: Cardinal;
  vmt: TClass;
  Proc: Pointer;
  Parent: Pointer;
  Addrs: PPointer;
  MessageID: SmallInt;
  M: TVPLListenerMethod;
  dynaTab: PDynaMethodTable;
begin
  vmt := Subscriber.ClassType;
  while True do
  begin
    dynaTab := PPointer(@PByte(vmt)[vmtDynamicTable])^;
    if dynaTab <> nil then
    begin
      for I := 0 to dynaTab.Count - 1 do
      begin
        MessageID := dynaTab.Selectors[I];
        if IsRegistered(MessageID) then
        begin
          Addrs := PPointer(PByte(@dynaTab.Selectors) + dynaTab.Count * SizeOf(dynaTab.Selectors[0]));
          Proc := PPointer(PByte(Addrs) + I * SizeOf(Pointer))^;
          TMethod(M).Data := Subscriber;
          TMethod(M).Code := Proc;
          Subscribe(Sender,TMessageID(MessageID),M);
        end;
      end;
    end;
    Parent := PPointer(@PByte(vmt)[vmtParent])^;
    if Parent = nil then Break;
    vmt := PPointer(Parent)^;
  end;
end;

constructor TVPLMessageService.Create;
begin
  FProcessing := 0;
  FLock := TObject.Create;
  FMsgIDMap := TMsgIDMap.Create(Self);
  FMessageTask := TMessageTask.Create(Self);
  FMessages := TDictionary<TMessageID,TMessageID>.Create;
end;

procedure TVPLMessageService.DecProcessing;
begin
  TInterlocked.Decrement(FProcessing);
end;

destructor TVPLMessageService.Destroy;
var
  SpinWait: TSpinWait;
begin
  FMessageTask.Terminate;
  Lock;
  try
    if FProcessing>0 then
    begin
      SpinWait.Reset;
      while FProcessing>0 do SpinWait.SpinCycle;
    end;
    FreeAndNil(FMessages);
    FreeAndNil(FMessageTask);
    FreeAndNil(FMsgIDMap);
  finally
    Unlock;
    FreeAndNil(FLock);
  end;
  inherited;
end;

function TVPLMessageService.GetMessage<P, V>(const Sender: TObject;
  const MessageID: TMessageID; const Param: P): V;
var
  Subscribers: TMessageSubscribers;
begin
  Subscribers := FMsgIDMap[MessageID];
  if Subscribers<>nil then
    Subscribers.SendMessageWithResult<P,V>(Sender,MessageID,Param,Result)
  else
    raise MessageException.Create('Message is not defined!');
end;

function TVPLMessageService.GetMessage<V>(const Sender: TObject; const MessageID: TMessageID; const Params: array of const): V;
var
  Subscribers: TMessageSubscribers;
begin
  Subscribers := FMsgIDMap[MessageID];
  if Subscribers<>nil then
    Subscribers.SendMessageWithResult<TArray<TVarRec>,V>(Sender,MessageID,CreateTuple(Params),Result)
  else
    raise MessageException.Create('Message is not defined!');
end;

function TVPLMessageService.GetMessage<V>(const Sender: TObject;
  const MessageID: TMessageID): V;
var
  Subscribers: TMessageSubscribers;
begin
  Subscribers := FMsgIDMap[MessageID];
  if Subscribers<>nil then
    Subscribers.SendMessageWithResult<V>(Sender,MessageID,Result)
  else
    raise MessageException.Create('Message is not defined!');
end;

class function TVPLMessageService.GetMessageService: TVPLMessageService;
var
  Service: TVPLMessageService;
begin
  if FMessageService = nil then
  begin
    Service := TVPLMessageService.Create;
    if AtomicCmpExchange(Pointer(FMessageService), Pointer(Service), nil) <> nil then
      Service.Free;
  end;
  Result := FMessageService;
end;

procedure TVPLMessageService.IncProcessing;
begin
  TInterlocked.Increment(FProcessing);
end;

function TVPLMessageService.IsRegistered(const MessageID: SmallInt): Boolean;
begin
  Lock;
  try
    Result := (FMessages.Count=0) or  FMessages.ContainsKey(MessageID);
  finally
    UnLock;
  end;
end;

procedure TVPLMessageService.Lock;
begin
  TMonitor.Enter(FLock);
end;

procedure TVPLMessageService.PostMessage(const Sender: TObject;const MessageID: TMessageID;const Synchronize: Boolean=False);
begin
  FMessageTask.PostMessage(Sender,MessageID,Synchronize);
end;

procedure TVPLMessageService.PostMessage(const Sender: TObject;const MessageID: TMessageID;const Message: TObject;const Synchronize: Boolean;const ADispose: Boolean);
begin
  FMessageTask.PostMessage(Sender,MessageID,Message,Synchronize,ADispose);
end;

procedure TVPLMessageService.PostMessage(const Sender: TObject;const MessageID: TMessageID;const Params: array of const;const Synchronize: Boolean);
begin
  FMessageTask.PostMessage(Sender,MessageID,Params,Synchronize);
end;

procedure TVPLMessageService.RegisterMessage(const MessageID: TMessageID);
begin
  Lock;
  try
    FMessages.Add(MessageID,MessageID);
  finally
    UnLock;
  end;
end;

procedure TVPLMessageService.RegisterMessage(
  const Messages: array of TMessageID);
begin
  Lock;
  try
    for var I := Low(Messages) to High(Messages) do
      FMessages.Add(Messages[I],Messages[I]);
  finally
    UnLock;
  end;
end;

procedure TVPLMessageService.Subscribe(const Subscriber: TObject;
  const MessageID: TMessageID);
begin
  Subscribe(Subscriber,nil,MessageID);
end;

procedure TVPLMessageService.Subscribe(const MessageID: TMessageID;
  const Listener: TVPLListener);
begin
  if IsRegistered(MessageID) then
    FMsgIDMap.Subscribe(nil,nil,MessageID,Listener);
end;

procedure TVPLMessageService.SendMessage(const Sender: TObject;const MessageID: TMessageID);
var
  Subscribers: TMessageSubscribers;
begin
  Subscribers := FMsgIDMap[MessageID];
  if Subscribers<>nil then
    Subscribers.SendMessage(Sender,MessageID);
end;

procedure TVPLMessageService.SendMessage(const Sender: TObject;const MessageID: TMessageID;
  const Params: TObject; const ADispose: Boolean);
var
  Subscribers: TMessageSubscribers;
begin
  Subscribers := FMsgIDMap[MessageID];
  if Subscribers<>nil then
    Subscribers.SendMessage(Sender,MessageID,Params,ADispose);
end;

procedure TVPLMessageService.SendMessage(const Sender: TObject;const MessageID: TMessageID;const Params: array of const);
var
  Subscribers: TMessageSubscribers;
begin
  Subscribers := FMsgIDMap[MessageID];
  if Subscribers<>nil then
    Subscribers.SendMessage(Sender,MessageID,Params);
end;

procedure TVPLMessageService.SendMessage(const Sender: TObject;const MessageID: TMessageID;const Params: TArray<TVarRec>);
var
  Subscribers: TMessageSubscribers;
begin
  Subscribers := FMsgIDMap[MessageID];
  if Subscribers<>nil then
    Subscribers.SendMessage(Sender,MessageID,Params);
end;

procedure TVPLMessageService.SendMessageWithResult<P, V>(const Sender: TObject;
  const MessageID: TMessageID; const Param: P; var Value: V);
var
  Subscribers: TMessageSubscribers;
begin
  Subscribers := FMsgIDMap[MessageID];
  if Subscribers<>nil then
    Subscribers.SendMessageWithResult<P,V>(Sender,MessageID,Param,Value)
  else
    raise MessageException.Create('Message is not defined!');
end;

procedure TVPLMessageService.SendMessage<P1, P2>(const Sender: TObject;
  const MessageID: TMessageID; const Param1: P1; const Param2: P2);
var
  Subscribers: TMessageSubscribers;
begin
  Subscribers := FMsgIDMap[MessageID];
  if Subscribers<>nil then
    Subscribers.SendMessage<P1,P2>(Sender,MessageID,Param1,Param2);
end;

procedure TVPLMessageService.SendMessage<P>(const Sender: TObject;const MessageID: TMessageID;
  const Param: P);
var
  Subscribers: TMessageSubscribers;
begin
  Subscribers := FMsgIDMap[MessageID];
  if Subscribers<>nil then
    Subscribers.SendMessage<P>(Sender,MessageID,Param);
end;

procedure TVPLMessageService.SendMessageWithResult<V>(const Sender: TObject; const MessageID: TMessageID; const Params: array of const; var Value: V);
begin
  SendMessageWithResult(Sender,MessageID,CreateTuple(Params),Value);
end;

procedure TVPLMessageService.SendMessageWithResult<V>(const Sender: TObject;
  const MessageID: TMessageID; var Value: V);
var
  Subscribers: TMessageSubscribers;
begin
  Subscribers := FMsgIDMap[MessageID];
  if Subscribers<>nil then
    Subscribers.SendMessageWithResult<V>(Sender,MessageID,Value)
  else
    raise MessageException.Create('Message is not defined!');
end;

procedure TVPLMessageService.AutoSubscribe(const Subscriber: TObject);
begin
  AutoSubscribe(Subscriber,nil);
end;

class destructor TVPLMessageService.UnInitialize;
begin
  FreeAndNil(FMessageService);
end;

procedure TVPLMessageService.UnLock;
begin
  TMonitor.Exit(FLock);
end;

procedure TVPLMessageService.UnRegisterMessage(const MessageID: TMessageID);
begin
  Lock;
  try
    FMessages.Remove(MessageID);
  finally
    UnLock;
  end;
end;

procedure TVPLMessageService.UnRegisterMessage(
  const Messages: array of TMessageID);
begin
  Lock;
  try
    for var I := Low(Messages) to High(Messages) do
      FMessages.Remove(Messages[I]);
  finally
    UnLock;
  end;
end;

procedure TVPLMessageService.Unsubscribe(const MessageID: TMessageID);
begin
  FMsgIDMap.Unsubscribe(MessageID);
end;

procedure TVPLMessageService.Unsubscribe(
  const ListenerMethod: TVPLListenerMethod);
begin
  FMsgIDMap.Unsubscribe(ListenerMethod);
end;

procedure TVPLMessageService.Unsubscribe(const Listener: TVPLListener);
begin
  FMsgIDMap.Unsubscribe(Listener);
end;

procedure TVPLMessageService.Unsubscribe(const Subscriber: TObject);
begin
  FMsgIDMap.Unsubscribe(Subscriber);
end;

procedure TVPLMessageService.Subscribe(const MessageID: TMessageID;const ListenerMethod: TVPLListenerMethod);
begin
  FMsgIDMap.Subscribe(TMethod(ListenerMethod).Data,nil,MessageID,ListenerMethod);
end;

procedure TVPLMessageService.Subscribe(const Subscriber, Sender: TObject;
  const MessageID: TMessageID);
begin
  FMsgIDMap.Subscribe(Subscriber,Sender,MessageID);
end;

procedure TVPLMessageService.Unsubscribe(const Subscriber: TObject;
  const MessageID: TMessageID);
begin
  FMsgIDMap.Unsubscribe(Subscriber,MessageID);
end;

{ TListenerData }

constructor TSubscriberData.Create(const ASubscriber,ASender: TObject;AListenerMethod: TVPLListenerMethod);
begin
  Sender := ASender;
  Subscriber := ASubscriber;
  Listener := nil;
  ListenerMethod := AListenerMethod;
end;

constructor TSubscriberData.Create(const ASubscriber,ASender: TObject;AListener: TVPLListener);
begin
  Sender := ASender;
  Subscriber := ASubscriber;
  Listener := AListener;
  ListenerMethod := nil;
end;

{ TMsgIDMap }

constructor TMsgIDMap.Create(MessageService: TVPLMessageService);
begin
  inherited Create;
  FLock := TObject.Create;
  FMessageService := MessageService;
  FMinID := -1;
  FMaxID := -1;
end;

destructor TMsgIDMap.Destroy;
begin
  Lock;
  try
    for var I := Low(FSubscribers) to High(FSubscribers) do
      FSubscribers[I].Free;
    SetLength(FSubscribers,0);
  finally
    UnLock;
    FreeAndNil(FLock);
  end;
  inherited Destroy;
end;

procedure TMsgIDMap.FreeListenerList(const MessageID: TMessageID);
var
  Index: TMessageID;
begin
  if (MessageID>=FMinID) and (MessageID<=FMaxID) then
  begin
    Index := MessageID-FMinID;
    FSubscribers[Index].Free;
    FSubscribers[Index] := nil;
  end;
end;

function TMsgIDMap.GetListenerData(
  const Index: TMessageID): TMessageSubscribers;
begin
  Result := nil;
  Lock;
  try
    if (Index>=FMinID) and (Index<=FMaxID) then
      Result := FSubscribers[Index-FMinID]
  finally
    UnLock;
  end;
end;

procedure TMsgIDMap.Lock;
begin
  TMonitor.Enter(FLock);
end;

function TMsgIDMap.SetListenerList(
  const MessageID: TMessageID): TMessageSubscribers;
var
  TmpArray: TArray<TMessageSubscribers>;
begin
  Lock;
  try
    if FMaxID=-1 then
    begin
      FMinID := MessageID;
      FMaxID := MessageID;
      SetLength(FSubscribers,1);
      Result := TMessageSubscribers.Create(FMessageService);
      FSubscribers[MessageID-FMinID] := Result;
    end
    else
    begin
      if MessageID<FMinID then
      begin
        SetLength(TmpArray,FMaxID-MessageID+1);
        TArray.Copy<TMessageSubscribers>(FSubscribers,TmpArray,0,FMinID-MessageID,Length(FSubscribers));
        FSubscribers := TmpArray;
        FMinID := MessageID;
        Result := TMessageSubscribers.Create(FMessageService);
        FSubscribers[MessageID-FMinID] := Result;
      end
      else if MessageID>FMaxID then
      begin
        SetLength(FSubscribers,MessageID-FMinID+1);
        FMaxID := MessageID;
        Result := TMessageSubscribers.Create(FMessageService);
        FSubscribers[MessageID-FMinID] := Result;
      end
      else
      begin
        Result := FSubscribers[MessageID-FMinID];
        if Result=nil then
        begin
          Result := TMessageSubscribers.Create(FMessageService);
          FSubscribers[MessageID-FMinID] := Result;
        end;
      end;
    end;
  finally
    UnLock;
  end;
end;

procedure TMsgIDMap.SetPriority(const Subscriber: TObject;
  const MessageID: TMessageID; const Priority: Integer);
var
  Subscribers: TMessageSubscribers;
begin
  Subscribers := GetListenerData(MessageID);
  if Subscribers<>nil then
    Subscribers.SetPriority(Subscriber,Priority);
end;

procedure TMsgIDMap.Subscribe(const Subscriber, Sender: TObject;
  const MessageID: TMessageID);
var
  M: TVPLListenerMethod;
begin
  TMethod(M).Code := GetDynaMethod(PPointer(Subscriber)^, MessageID);
  if TMethod(M).Code<>nil then
  begin
    TMethod(M).Data := Subscriber;
    Subscribe(Subscriber, Sender,MessageID,M);
  end;
end;

procedure TMsgIDMap.Unsubscribe(const MessageID: TMessageID);
begin
  Lock;
  try
    FreeListenerList(MessageID);
  finally
    UnLock;
  end;
end;

procedure TMsgIDMap.Unsubscribe(const Subscriber: TObject);
begin
  Lock;
  try
    for var I := Low(FSubscribers) to High(FSubscribers) do
    begin
      if FSubscribers[I]<>nil then
        FSubscribers[I].RemoveSubscriber(Subscriber);
    end;
  finally
    UnLock;
  end;
end;

procedure TMsgIDMap.Unsubscribe(const Listener: TVPLListener);
begin
  Lock;
  try
    for var I := Low(FSubscribers) to High(FSubscribers) do
    begin
      if FSubscribers[I]<>nil then
        FSubscribers[I].RemoveListener(Listener);
    end;
  finally
    UnLock;
  end;
end;

procedure TMsgIDMap.Subscribe(const Subscriber,Sender: TObject;
  const MessageID: TMessageID;const ListenerMethod: TVPLListenerMethod);
begin
  Lock;
  try
    SetListenerList(MessageID).AddListener(Subscriber,Sender,ListenerMethod);
  finally
    UnLock;
  end;
end;

procedure TMsgIDMap.Unsubscribe(const ListenerMethod: TVPLListenerMethod);
begin
  Lock;
  try
    for var I := Low(FSubscribers) to High(FSubscribers) do
    begin
      if FSubscribers[I]<>nil then
        FSubscribers[I].RemoveListener(ListenerMethod);
    end;
  finally
    UnLock;
  end;
end;

procedure TMsgIDMap.Subscribe(const Subscriber,Sender: TObject;const MessageID: TMessageID;
  const Listener: TVPLListener);
begin
  Lock;
  try
    SetListenerList(MessageID).AddListener(Subscriber,Sender,Listener);
  finally
    UnLock;
  end;
end;

procedure TMsgIDMap.UnLock;
begin
  TMonitor.Exit(FLock);
end;

procedure TMsgIDMap.Unsubscribe(const Subscriber: TObject;
  const MessageID: TMessageID);
var
  Subscribers: TMessageSubscribers;
begin
  Subscribers := GetListenerData(MessageID);
  if Subscribers<>nil then
    Subscribers.RemoveSubscriber(Subscriber);
end;

{ TMessageSubscribers }

procedure TMessageSubscribers.AddListener(const Subscriber,Sender: TObject;const Listener: TVPLListener);
begin
  Lock;
  try
    FList.Add(TSubscriberData.Create(Subscriber,Sender,Listener));
  finally
    UnLock;
  end;
end;

procedure TMessageSubscribers.AddListener(const Subscriber,Sender: TObject;const ListenerMethod: TVPLListenerMethod);
var
  Added: Boolean;
  SubscriberData: TSubscriberData;
begin
  Lock;
  try
    if Sender=nil then
      FList.Add(TSubscriberData.Create(Subscriber,Sender,ListenerMethod))
    else
    begin
      Added := False;
      for var I := 0 to FList.Count-1 do
      begin
        if (FList[I].Subscriber=Subscriber) and (TMethod(FList[I].ListenerMethod)=TMethod(ListenerMethod))  then
        begin
          SubscriberData := FList[I];
          SubscriberData.Sender := Sender;
          FList[I] := SubscriberData;
          Added := True;
          Break;
        end;
      end;
      if not Added then
        FList.Add(TSubscriberData.Create(Subscriber,Sender,ListenerMethod));
    end;
  finally
    Unlock;
  end;
end;

constructor TMessageSubscribers.Create(MessageService: TVPLMessageService);
begin
  FLock := TObject.Create;
  FMessageService := MessageService;
  FList:= TList<TSubscriberData>.Create;
end;

destructor TMessageSubscribers.Destroy;
begin
  Lock;
  try
    FreeAndNil(FList);
  finally
    UnLock;
    FreeAndNil(FLock);
  end;
  inherited;
end;

function TMessageSubscribers.GetMessage<P, V>(const Sender: TObject;
  const MessageID: TMessageID; const Param: P): V;
begin
  SendMessageWithResult<P,V>(Sender,MessageID,Param,Result);
end;

function TMessageSubscribers.GetMessage<V>(const Sender: TObject;
  const MessageID: TMessageID): V;
begin
  SendMessageWithResult<V>(Sender,MessageID,Result);
end;

procedure TMessageSubscribers.Lock;
begin
  TMonitor.Enter(FLock);
end;

procedure TMessageSubscribers.RemoveListener(
  const ListenerMethod: TVPLListenerMethod);
begin
  Lock;
  try
    for var I := FList.Count-1 downto 0 do
    begin
      if TMethod(FList[I].ListenerMethod)=TMethod(ListenerMethod) then
        FList.Delete(I);
    end;
  finally
    UnLock;
  end;
end;

procedure TMessageSubscribers.SendMessage(const Sender: TObject;const MessageID: TMessageID;
  const Param: TObject; const ADispose: Boolean);
var
  M: TVPLMessage<TObject,TObject>;
  Listeners: TArray<TSubscriberData>;
begin
  Lock;
  try
    Listeners := FList.ToArray;
  finally
    UnLock;
  end;
  FMessageService.IncProcessing;
  try
    M := TVPLMessage<TObject,TObject>.Create(Sender,MessageID,Param);
    for var I := Low(Listeners) to High(Listeners) do
    begin
      if (Listeners[I].Sender=nil) or (Listeners[I].Sender=Sender) then
      begin
        if Assigned(Listeners[I].ListenerMethod) then
          Listeners[I].ListenerMethod(M)
        else if Assigned(Listeners[I].Listener) then
          Listeners[I].Listener(M)
        else
          Listeners[I].Subscriber.Dispatch(M);
      end;
    end;
  finally
    FMessageService.DecProcessing;
    if ADispose then
      FreeAndNil(Param);
  end;
end;

procedure TMessageSubscribers.SendMessage(const Sender: TObject;const MessageID: TMessageID;
  const Param: TObject);
begin
  SendMessage(Sender,MessageID,Param,True);
end;

procedure TMessageSubscribers.SendMessage(const Sender: TObject;const MessageID: TMessageID);
var
  M: TVPLMessage<TObject>;
  Listeners: TArray<TSubscriberData>;
begin
  Lock;
  try
    Listeners := FList.ToArray;
  finally
    UnLock;
  end;
  FMessageService.IncProcessing;
  try
    M := TVPLMessage<TObject>.Create(Sender,MessageID);
    for var I := Low(Listeners) to High(Listeners) do
    begin
      if (Listeners[I].Sender=nil) or (Listeners[I].Sender=Sender) then
      begin
        if Assigned(Listeners[I].ListenerMethod) then
          Listeners[I].ListenerMethod(M)
        else if Assigned(Listeners[I].Listener) then
          Listeners[I].Listener(M)
        else
          Listeners[I].Subscriber.Dispatch(M);
      end;
    end;
  finally
    FMessageService.DecProcessing;
  end;
end;

procedure TMessageSubscribers.SendMessage(const Sender: TObject;const MessageID: TMessageID;const Params: array of const);
var
  TupleParam: TVPLTuple;
begin
  SetLength(TupleParam,Length(Params));
  for var I := Low(Params) to High(Params) do
    TupleParam[I] := Params[I];
  SendMessage(Sender,MessageID,TupleParam);
end;

procedure TMessageSubscribers.SendMessage(const Sender: TObject;const MessageID: TMessageID;const Params: TArray<TVarRec>);
var
  M: TVPLMessage<TObject,TVPLTuple>;
  Listeners: TArray<TSubscriberData>;
begin
  Lock;
  try
    Listeners := FList.ToArray;
  finally
    UnLock;
  end;
  FMessageService.IncProcessing;
  try
    M := TVPLMessage<TObject,TVPLTuple>.Create(Sender,MessageID,Params);
    for var I := Low(Listeners) to High(Listeners) do
    begin
      if (Listeners[I].Sender=nil) or (Listeners[I].Sender=Sender) then
      begin
        if Assigned(Listeners[I].ListenerMethod) then
          Listeners[I].ListenerMethod(M)
        else if Assigned(Listeners[I].Listener) then
          Listeners[I].Listener(M)
        else
          Listeners[I].Subscriber.Dispatch(M);
      end;
    end;
  finally
    FMessageService.DecProcessing;
  end;
end;

procedure TMessageSubscribers.SendMessageWithResult<V>(
  const Sender: TObject;const MessageID: TMessageID; var Value: V);
var
  M: TVPLMessage<TObject,V>;
  Listeners: TArray<TSubscriberData>;
begin
  Lock;
  try
    Listeners := FList.ToArray;
  finally
    UnLock;
  end;
  FMessageService.IncProcessing;
  try
    M := TVPLMessage<TObject,V>.Create(Sender,MessageID,Value);
    for var I := Low(Listeners) to High(Listeners) do
    begin
      if (Listeners[I].Sender=nil) or (Listeners[I].Sender=Sender) then
      begin
        if Assigned(Listeners[I].ListenerMethod) then
          Listeners[I].ListenerMethod(M)
        else if Assigned(Listeners[I].Listener) then
          Listeners[I].Listener(M)
        else
          Listeners[I].Subscriber.Dispatch(M);
      end;
      Value := M.Param;
      Break;
    end;
  finally
    FMessageService.DecProcessing;
  end;
end;

procedure TMessageSubscribers.SetPriority(const Subscriber: TObject;
  const Priority: Integer);
begin
  Lock;
  try
    for var I := 0 to FList.Count-1 do
    begin
      if (FList[I].Subscriber=Subscriber) or
        Assigned(FList[I].ListenerMethod) and (TMethod(FList[I].ListenerMethod).Data=Subscriber) then
      begin
        if I>Priority then
          FList.Move(I,Priority);
        Break;
      end;
    end;
  finally
    UnLock;
  end;
end;

procedure TMessageSubscribers.SetSender(const Subscriber, Sender: TObject);
var
  SubscriberData: TSubscriberData;
begin
  Lock;
  try
   for var I := 0 to FList.Count-1 do
   begin
     if FList[I].Subscriber=Subscriber then
     begin
       SubscriberData := FList[I];
       SubscriberData.Sender := Sender;
       FList[I] := SubscriberData;
       Break;
     end;
   end;
  finally
    UnLock;
  end;
end;

procedure TMessageSubscribers.UnLock;
begin
  TMonitor.Exit(FLock);
end;

procedure TMessageSubscribers.SendMessageWithResult<P, V>(const Sender: TObject;
  const MessageID: TMessageID; const Param: P; var Value: V);
var
  M: TVPLMessage<TObject,P,V>;
  Listeners: TArray<TSubscriberData>;
begin
  Lock;
  try
    Listeners := FList.ToArray;
  finally
    UnLock;
  end;
  FMessageService.IncProcessing;
  try
    M := TVPLMessage<TObject,P,V>.Create(Sender,MessageID,Param,Value);
    for var I := Low(Listeners) to High(Listeners) do
    begin
      if (Listeners[I].Sender=nil) or (Listeners[I].Sender=Sender) then
      begin
        if Assigned(Listeners[I].ListenerMethod) then
          Listeners[I].ListenerMethod(M)
        else if Assigned(FList[I].Listener) then
          Listeners[I].Listener(M)
        else
          Listeners[I].Subscriber.Dispatch(M);
      end;
    end;
    Value := M.Param2;
  finally
    FMessageService.DecProcessing;
  end;
end;

procedure TMessageSubscribers.SendMessage<P1,P2>(const Sender: TObject;
  const MessageID: TMessageID; const Param1: P1; const Param2: P2);
var
  TmpObj: TObject;
  M: TVPLMessage<TObject,P1,P2>;
  Listeners: TArray<TSubscriberData>;
begin
  Lock;
  try
    Listeners := FList.ToArray;
  finally
    UnLock;
  end;
  FMessageService.IncProcessing;
  try
    M := TVPLMessage<TObject,P1,P2>.Create(Sender,MessageID,Param1,Param2);
    for var I := Low(Listeners) to High(Listeners) do
    begin
      if (Listeners[I].Sender=nil) or (Listeners[I].Sender=Sender) then
      begin
        if Assigned(FList[I].ListenerMethod) then
          Listeners[I].ListenerMethod(M)
        else if Assigned(Listeners[I].Listener) then
          Listeners[I].Listener(M)
        else
          Listeners[I].Subscriber.Dispatch(M);
      end;
    end;
  finally
    FMessageService.DecProcessing;
  end;
end;

procedure TMessageSubscribers.SendMessage<P>(const Sender: TObject;
  const MessageID: TMessageID; const Param: P);
var
  M: TVPLMessage<TObject,P>;
  Listeners: TArray<TSubscriberData>;
begin
  Lock;
  try
    Listeners := FList.ToArray;
  finally
    UnLock;
  end;
  FMessageService.IncProcessing;
  try
    M := TVPLMessage<TObject,P>.Create(Sender,MessageID,Param);
    for var I := Low(Listeners) to High(Listeners) do
    begin
      if (Listeners[I].Sender=nil) or (Listeners[I].Sender=Sender) then
      begin
        if Assigned(FList[I].ListenerMethod) then
          Listeners[I].ListenerMethod(M)
        else if Assigned(Listeners[I].Listener) then
          Listeners[I].Listener(M)
        else
          Listeners[I].Subscriber.Dispatch(M);
      end;
    end;
  finally
    FMessageService.DecProcessing;
  end;
end;

procedure TMessageSubscribers.RemoveListener(const Listener: TVPLListener);
begin
  Lock;
  try
    for var I := FList.Count-1 downto 0 do
    begin
      if FList[I].Listener=TVPLListener(Listener) then
        FList.Delete(I);
    end;
  finally
    UnLock;
  end;
end;

procedure TMessageSubscribers.RemoveSubscriber(const Subscriber: TObject);
var
   SubscriberData: TSubscriberData;
begin
  Lock;
  try
    for var I := FList.Count-1 downto 0 do
    begin
      if (FList[I].Subscriber=Subscriber) or (TMethod(FList[I].ListenerMethod).Data=Subscriber) then
        FList.Delete(I)
      else
      begin
        if FList[I].Sender=Subscriber  then
        begin
          SubscriberData := FList[I];
          SubscriberData.Sender := nil;
          FList[I] := SubscriberData;
        end
      end;
    end;
  finally
    UnLock;
  end;
end;

{ TMessageTask }

procedure TMessageTask.AddObjectQueue(const Sender: TObject;const MessageID: TMessageID;
  const Param: TObject; const Synchronize,ADispose: Boolean);
var
  TaskData: TTaskData;
begin
  if not FTerminated then
  begin
    TaskData := TObjectTaskData.Create(Sender,MessageID,Param,ADispose,Synchronize);
    Lock;
    try
      FMessageQueue.Enqueue(TaskData);
    finally
      UnLock;
    end;
    Start;
  end;
end;

procedure TMessageTask.AddQueue(const Sender: TObject; const MessageID: TMessageID; const Synchronize: Boolean);
var
  TaskData: TTaskData;
begin
  if not FTerminated then
  begin
    TaskData := TTaskData.Create(Sender,MessageID,Synchronize);
    Lock;
    try
      FMessageQueue.Enqueue(TaskData);
    finally
      UnLock;
    end;
    Start;
  end;
end;

procedure TMessageTask.AddTupleQueue(const Sender: TObject; const MessageID: TMessageID; const Params: TVPLTuple; const Synchronize: Boolean);
var
  TaskData: TTaskData;
begin
  if not FTerminated then
  begin
    TaskData := TTupleTaskData.Create(Sender,MessageID,Params,Synchronize);
    Lock;
    try
      FMessageQueue.Enqueue(TaskData);
    finally
      UnLock;
    end;
    Start;
  end;
end;

constructor TMessageTask.Create(MessageService: TVPLMessageService);
begin
  FLock := TObject.Create;
  FMessageService := MessageService;
  FMessageQueue := TQueue<TTaskData>.Create;
  FTask := CreateTask;
end;

function TMessageTask.CreateTask: ITask;
begin
  Result := TTask.Create (procedure ()
  var
    TaskData: TTaskData;
  begin
    FTerminated := False;
    while not FTerminated do
    begin
      Lock;
      try
        if FMessageQueue.Count>0 then
          TaskData := FMessageQueue.Dequeue
        else
          Break;
      finally
        UnLock;
      end;
      try
        try
          TaskData.SendMessage(FMessageService);
        finally
          FreeAndNil(TaskData);
        end;
      except on E: Exception do
        ;
      end;
    end;
  end);
end;

destructor TMessageTask.Destroy;
var
  SpinWait: TSpinWait;
  TmpMessages: TArray<TTaskData>;
begin
  Terminate;
  Lock;
  try
    if FTask<>nil then
    begin
      SpinWait.Reset;
      while FTask.Status = TTaskStatus.Running do SpinWait.SpinCycle;
      FTask := nil;
    end;
    FMessageQueue.TrimExcess; //???
    TmpMessages := FMessageQueue.List;
    for var I := Low(TmpMessages) to High(TmpMessages) do
      TmpMessages[I].Free;
    FreeAndNil(FMessageQueue);
  finally
    UnLock;
    FreeAndNil(FLock);
  end;
  inherited;
end;

procedure TMessageTask.Lock;
begin
  TMonitor.Enter(FLock);
end;

procedure TMessageTask.PostMessage(const Sender: TObject;const MessageID: TMessageID;
  const Param: TObject;const Synchronize,ADispose: Boolean);
begin
  AddObjectQueue(Sender,MessageID,Param,Synchronize,ADispose);
end;

procedure TMessageTask.PostMessage(const Sender: TObject;const MessageID: TMessageID;const Synchronize: Boolean);
begin
  AddQueue(Sender,MessageID,Synchronize);
end;

procedure TMessageTask.PostMessage(const Sender: TObject;const MessageID: TMessageID;const Params: array of const;const Synchronize: Boolean);
var
  TupleParam: TVPLTuple;
begin
  SetLength(TupleParam,Length(Params));
  for var I := Low(Params) to High(Params) do
    TupleParam[I] := Params[I];
  PostMessage(Sender,MessageID,TupleParam,Synchronize);
end;

procedure TMessageTask.PostMessage(const Sender: TObject;const MessageID: TMessageID;const Params: TVPLTuple;const Synchronize: Boolean);
begin
  AddTupleQueue(Sender,MessageID,Params,Synchronize);
end;

procedure TMessageTask.Start;
begin
  if FTask.Status=TTaskStatus.Completed then //in [TTaskStatus.Created, TTaskStatus.WaitingToRun, TTaskStatus.Completed] then
    FTask := CreateTask;
  if  FTask.Status=TTaskStatus.Created then
    FTask.Start;
end;

procedure TMessageTask.Terminate;
begin
  FTerminated := True;
end;

procedure TMessageTask.UnLock;
begin
  TMonitor.Exit(FLock);
end;

{ TMeeeagePair }

constructor TMeeeagePair.Create;
begin
  Create(Self);
end;

constructor TMeeeagePair.Create(Supervisor: TObject);
begin
  FPairCount := 0;
  FSupervisor := Supervisor;
  FMessageService := TVPLMessageService.Create;
end;

destructor TMeeeagePair.Destroy;
begin
  FreeAndNil(FMessageService);
  inherited;
end;

function TMeeeagePair.GetMessage<P, V>(const Sender: TObject;
  const MessageID: TMessageID; const Param: P): V;
begin
  Result := FMessageService.GetMessage<P,V>(Sender,MessageID,Param);
end;

function TMeeeagePair.GetMessage<V>(const Sender: TObject; const MessageID: TMessageID; const Params: array of const): V;
begin
  Result := FMessageService.GetMessage<V>(Sender,MessageID,Params);
end;

function TMeeeagePair.GetMessage<V>(const Sender: TObject;
  const MessageID: TMessageID): V;
begin
  Result := FMessageService.GetMessage<V>(Sender,MessageID);
end;

procedure TMeeeagePair.Pairing(const Pair: TObject);
begin
  if Pair<>FSupervisor then
  begin
    FMessageService.AutoSubscribe(Pair);
    Inc(FPairCount);
  end;
end;

procedure TMeeeagePair.PostMessage(const Sender: TObject;const MessageID: TMessageID;const Synchronize: Boolean=False);
begin
  FMessageService.PostMessage(Sender,MessageID,Synchronize);
end;

procedure TMeeeagePair.PostMessage(const Sender: TObject;const MessageID: TMessageID;
  const Param: TObject;const Synchronize: Boolean;const ADispose: Boolean);
begin
  FMessageService.PostMessage(Sender,MessageID,Param,Synchronize,ADispose);
end;

procedure TMeeeagePair.PostMessage(const Sender: TObject;const MessageID: TMessageID;const Params: array of const;const Synchronize: Boolean=False);
begin
  FMessageService.PostMessage(Sender,MessageID,Params,Synchronize);
end;

procedure TMeeeagePair.PostMessage(const Sender: TObject;const MessageID: TMessageID;const Params: TVPLTuple;const Synchronize: Boolean=False);
begin
  FMessageService.PostMessage(Sender,MessageID,Params,Synchronize);
end;

procedure TMeeeagePair.RegisterMessage(const MessageID: TMessageID);
begin
  FMessageService.RegisterMessage(MessageID);
end;

procedure TMeeeagePair.RegisterMessage(const Messages: array of TMessageID);
begin
  FMessageService.RegisterMessage(Messages);
end;

procedure TMeeeagePair.SendMessage(const Sender: TObject;const MessageID: TMessageID;
  const Param: TObject);
begin
  FMessageService.SendMessage(Sender,MessageID,Param);
end;

procedure TMeeeagePair.SendMessage(const Sender: TObject;const MessageID: TMessageID;
  const Param: TObject; const ADispose: Boolean);
begin
  FMessageService.SendMessage(Sender,MessageID,Param,ADispose);
end;

procedure TMeeeagePair.SendMessage(const Sender: TObject;const MessageID: TMessageID);
begin
  FMessageService.SendMessage(Sender,MessageID);
end;

procedure TMeeeagePair.SendMessage(const Sender: TObject;const MessageID: TMessageID;const Params: array of const);
begin
  FMessageService.SendMessage(Sender,MessageID,Params);
end;

procedure TMeeeagePair.SendMessage(const Sender: TObject;const MessageID: TMessageID;const Params: TVPLTuple);
begin
  FMessageService.SendMessage(Sender,MessageID,Params);
end;

procedure TMeeeagePair.SendMessageWithResult<V>(const Sender: TObject;const MessageID: TMessageID;
  var Value: V);
begin
  FMessageService.SendMessageWithResult<V>(Sender,MessageID,Value);
end;

procedure TMeeeagePair.SubscribeSupervisor;
begin
  FMessageService.AutoSubscribe(Supervisor);
end;

procedure TMeeeagePair.SendMessageWithResult<P, V>(const Sender: TObject;
  const MessageID: TMessageID; const Param: P; var Value: V);
begin
  FMessageService.SendMessageWithResult<P,V>(Sender,MessageID,Param,Value);
end;

procedure TMeeeagePair.SendMessageWithResult<V>(const Sender: TObject; const MessageID: TMessageID; const Params: array of const; var Value: V);
begin
  FMessageService.SendMessageWithResult<V>(Sender,MessageID,Params,Value);
end;

procedure TMeeeagePair.SendMessage<P1, P2>(const Sender: TObject;
  const MessageID: TMessageID; const Param1: P1; const Param2: P2);
begin
  FMessageService.SendMessage<P1,P2>(Sender,MessageID,Param1,Param2);
end;

procedure TMeeeagePair.SendMessage<P>(const Sender: TObject;const MessageID: TMessageID;
  const Param: P);
begin
  FMessageService.SendMessage<P>(Sender,MessageID,Param);
end;

procedure TMeeeagePair.UnPairing(const Pair: TObject);
begin
  if Pair<>FSupervisor then
  begin
    FMessageService.Unsubscribe(Pair);
    Dec(FPairCount);
  end;
end;

procedure TMeeeagePair.UnRegisterMessage(const MessageID: TMessageID);
begin
  FMessageService.UnRegisterMessage(MessageID);
end;

procedure TMeeeagePair.UnRegisterMessage(const Messages: array of TMessageID);
begin
  FMessageService.UnRegisterMessage(Messages);
end;

{ TVPLMessage }
{
constructor TVPLMessage.Create(const ASender: TObject;const AMsgID: TMessageID);
begin
  MsgID := AMsgID;
  Sender := ASender;
end;  }

{ TVPLMessage<S> }

constructor TVPLMessage<S>.Create(const ASender: S;const AMsgID: TMessageID);
begin
  MsgID := AMsgID;
  Sender := ASender;
end;

{ TVPLMessage<S, P> }

constructor TVPLMessage<S, P>.Create(const ASender: S;
  const AMsgID: TMessageID;const AParam: P);
begin
  MsgID := AMsgID;
  Sender := ASender;
  Param := AParam;
end;

procedure TVPLMessageService.Subscribe(const Sender: TObject;
  const MessageID: TMessageID; const ListenerMethod: TVPLListenerMethod);
begin
   FMsgIDMap.Subscribe(TMethod(ListenerMethod).Data,Sender,MessageID,ListenerMethod);
end;

procedure TVPLMessageService.SubscribePriority(const Subscriber: TObject;
  const MessageID: TMessageID; const Priority: Integer);
begin
  FMsgIDMap.SetPriority(Subscriber,MessageID,Priority);
end;

procedure TVPLMessageService.Subscribe(const Sender: TObject;
  const MessageID: TMessageID; const Listener: TVPLListener);
begin
  FMsgIDMap.Subscribe(nil,Sender,MessageID,Listener);
end;

{ TVPLMessage<S, P1, P2> }

constructor TVPLMessage<S, P1, P2>.Create(const ASender: S;
  const AMsgID: TMessageID; const AParam1: P1; const AParam2: P2);
begin
  MsgID := AMsgID;
  Sender := ASender;
  Param1 := AParam1;
  Param2 := AParam2;
end;

{ TVarRecHelper }

function TVarRecHelper.ToString: String;
begin
  case VType of
       vtInteger: Result := IntToStr(vInteger);
       vtBoolean: if VBoolean then Result :='True' else Result := 'False';
          vtChar: Result := String(VChar);
      vtExtended: Result := FloatToStr(VExtended^);
      vtWideChar:  Result := VWideChar;
    vtAnsiString:  Result := String(AnsiString(VAnsiString));
      vtCurrency:  Result := FloatToStr(VCurrency^);
    vtWideString:  Result := WideString(VWideString);
         vtInt64:  Result := IntToStr(VInt64^);
 vtUnicodeString:  Result := UnicodeString(VUnicodeString);
//        vtObject,
//        vtClass,
//     vtInterface: Result := UnicodeString(VUnicodeString);
    else
      raise Exception.Create('Not supported type!');;
  end;
end;

{ TTaskData }

constructor TTaskData.Create(Sender: TObject; const MessageID: TMessageID; const Synchronize: Boolean);
begin
  FSender := Sender;
  FMessageID := MessageID;
  FSynchronize := Synchronize;
end;

procedure TTaskData.DoSendMessage(const MessageService: TVPLMessageService);
begin
  MessageService.SendMessage(FSender,FMessageID);
end;

procedure TTaskData.SendMessage(const MessageService: TVPLMessageService);
begin
  if FSynchronize then
  begin
    TThread.Synchronize(TThread.Current,procedure
    begin
      DoSendMessage(MessageService);
    end);
  end
  else
    DoSendMessage(MessageService);
end;

{ TObjectTaskData }

constructor TObjectTaskData.Create(Sender: TObject; const MessageID: TMessageID; const Param: TObject; const ADispose, Synchronize: Boolean);
begin
  inherited Create(Sender,MessageID,Synchronize);
  FParam := Param;
  FDispose := ADispose;
end;

destructor TObjectTaskData.Destroy;
begin
  if (FParam<>nil) and FDispose then
    FreeAndNil(FParam);
  inherited;
end;

procedure TObjectTaskData.DoSendMessage(const MessageService: TVPLMessageService);
begin
  try
    MessageService.SendMessage(FSender,FMessageID,FParam,FDispose);
  finally
    FParam := nil
  end;
end;

{ TTupleTaskData }

constructor TTupleTaskData.Create(Sender: TObject; const MessageID: TMessageID; const Params: TVPLTuple; const Synchronize: Boolean);
begin
  inherited Create(Sender,MessageID,Synchronize);
  FParams := Params;
end;

destructor TTupleTaskData.Destroy;
begin
  inherited;
end;

procedure TTupleTaskData.DoSendMessage(const MessageService: TVPLMessageService);
begin
  MessageService.SendMessage(FSender,FMessageID,FParams);
end;

initialization
  MessageService := TVPLMessageService.DefaultMessageService;
finalization
  MessageService := nil;
end.
