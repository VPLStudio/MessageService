 (*
  *                IPC - IPC for Delphi
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

unit VPL.IPC;

{$DEFINE MESSAGESERVICE}
interface
uses
  System.Types, System.UITypes, System.Classes,System.SysUtils,FMX.Controls.Model,System.TypInfo,
  System.Generics.Collections,System.Messaging,FMX.Presentation.Messages,System.JSON,System.Rtti,
  System.Threading,System.SyncObjs,System.JSON.Serializers,System.IOUtils,IdTCPConnection,
  IdContext, IdIOHandler,IdBaseComponent, IdComponent, IdTCPClient,IdGlobal,IdTCPServer, IdSocketHandle
  {$IFDEF MESSAGESERVICE},VPL.Messaging{$ENDIF};

const
  JSONBoolStrs: array[Boolean] of String=('false','true');

  IPC_PORT = 10240;
  LOCAL_IP = '127.0.0.1';

  //IPC Value Type
  ivNull        =     255;
  ivUnknow      =     0;
  ivChar        =     1;
  ivBoolean     =     2;
  ivInt8        =     3;
  ivInt16       =     4;
  ivInt32       =     5;
  ivInt64       =     6;
  ivUInt8       =     7;
  ivUInt16      =     8;
  ivUInt32      =     9;
  ivUInt64      =     10;
  ivSingle      =     11;
  ivDouble      =     12;
  ivExtended    =     13;
  ivCurrency    =     14;
  IvString      =     15;
  ivDate        =     16;
  ivTime        =     17;
  ivDateTime    =     18;
  ivObject      =     19;
  ivClass       =     20;
  ivConstArray  =     21;
  ivCustom      =     22;

type
  TIPCValue = record
  public
    class operator Implicit(const Value: Char): TIPCValue;
    class operator Implicit(const Value: Boolean): TIPCValue;
    class operator Implicit(const Value: Int8): TIPCValue;
    class operator Implicit(const Value: Int16): TIPCValue;
    class operator Implicit(const Value: Int32): TIPCValue;
    class operator Implicit(const Value: Int64): TIPCValue;
    class operator Implicit(const Value: UInt8): TIPCValue;
    class operator Implicit(const Value: UInt16): TIPCValue;
    class operator Implicit(const Value: UInt32): TIPCValue;
    class operator Implicit(const Value: UInt64): TIPCValue;
    class operator Implicit(const Value: Single): TIPCValue;
    class operator Implicit(const Value: Double): TIPCValue;
    class operator Implicit(const Value: Extended): TIPCValue;
    class operator Implicit(const Value: Currency): TIPCValue;
    class operator Implicit(const Value: String): TIPCValue;
    class operator Implicit(const Value: TDate): TIPCValue;
    class operator Implicit(const Value: TTime): TIPCValue;
    class operator Implicit(const Value: TDateTime): TIPCValue;
    class operator Implicit(const Value: TObject): TIPCValue;
    class operator Implicit(const Value: TClass): TIPCValue;
    class function From<T>(const Value: T): TIPCValue; overload; static;
    class function From(const Value: array of const): TIPCValue; overload; static;
    class function From(const Value: Char): TIPCValue; overload; static;
    class function From(const Value: Boolean): TIPCValue; overload; static;
    class function From(const Value: Int8): TIPCValue; overload; static;
    class function From(const Value: Int16): TIPCValue; overload; static;
    class function From(const Value: Int32): TIPCValue; overload; static;
    class function From(const Value: Int64): TIPCValue; overload; static;
    class function From(const Value: UInt8): TIPCValue; overload; static;
    class function From(const Value: UInt16): TIPCValue; overload; static;
    class function From(const Value: UInt32): TIPCValue; overload; static;
    class function From(const Value: UInt64): TIPCValue; overload; static;
    class function From(const Value: Single): TIPCValue; overload; static;
    class function From(const Value: Double): TIPCValue; overload; static;
    class function From(const Value: Extended): TIPCValue; overload; static;
    class function From(const Value: Currency): TIPCValue; overload; static;
    class function From(const Value: String): TIPCValue; overload; static;
    class function From(const Value: TDate): TIPCValue; overload; static;
    class function From(const Value: TTime): TIPCValue; overload; static;
    class function From(const Value: TObject): TIPCValue; overload; static;
    class function From(const Value: TClass): TIPCValue; overload; static;
    class function FromJSON(const Value: String): TIPCValue; overload; static;
    class function Null: TIPCValue; static;
    function ToJSON: String;
    function AsChar: Char; inline;
    function AsBoolean: Boolean; inline;
    function AsInt8: Int8; inline;
    function AsInt16: Int16; inline;
    function AsInt32: Int32; inline;
    function AsInt64: Int64; inline;
    function AsUInt8: UInt8; inline;
    function AsUInt16: UInt16; inline;
    function AsUInt32: UInt32; inline;
    function AsUInt64: UInt64; inline;
    function AsString: string; inline;
    function AsInteger: Integer; inline;
    function AsSingle: Single; inline;
    function AsDouble: Double; inline;
    function AsExtended: Extended; inline;
    function AsCurrency: Currency; inline;
    function AsDateTime:  TDateTime; inline;
    function AsDate:  TDate; inline;
    function AsTime:  TTime; inline;
    function AsType<T>: T;
    function IsNull: Boolean; inline;
  private
   VType: Byte;
   _Data: String;
   class function ConstArrayToJSON(const Value: array of const): String; static;
   class function JSONToConstArray(const Value: String): TArray<TVarRec>; static;
   case Byte of
     ivChar        :     (VChar: Char);
     ivBoolean     :     (VBoolean : Boolean);
     ivInt32       :     (VInt32: Int32);
     ivInt64       :     (VInt64: Int64);
     ivUInt32      :     (VUInt32: UInt32);
     ivUInt64      :     (VUInt64: UInt64);
     ivExtended    :     (VExtended: Extended);
     ivCurrency    :     (VCurrency: Currency);
     ivDateTime    :     (VDateTime: TDateTime);
  end;

  TIPCFrameType = (ifUnknow,ifCommand,ifResponse);
  TIPCCommand = (icGet,icSet,icQuery,icRegister,icUnRegister,icDisconnect,icSwitchServer,icMainServer);
  TIPCResponse =(IPC_ERROR,IPC_NOTSUPPORT,IPC_OK,IPC_WAIT,IPC_RESULT,IPC_NOP,IPC_DOWN);

  PIPCResponseHead = ^TIPCResponseHead;
  TIPCResponseHead = packed record
    FrameType: TIPCFrameType;
    Status: TIPCResponse;
  end;

  PIPCCommandHead = ^TIPCCommandHead;
  TIPCCommandHead = packed record
   FrameType: TIPCFrameType;
   MessageID: TMessageID;
   Command: TIPCCommand;
   Broadcast: Boolean;
  end;

  TServerMeta = record
    IP: String;
    Port: Word;
  end;

  TIPCMode = (imUnkown,imAuto,imServer,imClient);

  TVPLIPC = class;

  TSetMessageEvent = procedure(const MessageID: TMessageID;const Param: TIPCValue) of object;
  TGetMessageEvent = procedure(const MessageID: TMessageID;const Param: TIPCValue;out Ret: TIPCValue) of object;

  IPCException = class(Exception);

  TVPLIPC = class
  private
    FMode: TIPCMode;
    FClient: TIdTCPClient;
    FMainServer: TIdTCPServer;
    FClientServer: TIdTCPServer;
    {$IFDEF MESSAGESERVICE}
    FMessageService: TVPLMessageService;
    {$ENDIF}
    FOnGetMessage: TGetMessageEvent;
    FOnSetMessage: TSetMessageEvent;

    procedure IPCNotStart;
    function GetServerPort: Word;
    function StartMainServer: Boolean;
    function ConnectToMainServer: Boolean; overload;
    function ConnectToMainServer(const Port: word): Boolean; overload;
    procedure DoMainServerExecute(AContext: TIdContext);
    procedure DoClientServerDisconnect(AContext: TIdContext);
    procedure DoClientServerExecute(AContext: TIdContext);
    procedure DoClientModeExecute(AContext: TIdContext;const AData: TIdBytes);
    procedure DoServerModeExecute(AContext: TIdContext;const AData: TIdBytes);

    function DoGetMessage(const IOHandler: TIdIOHandler;const Buffer: TIdBytes): TIPCValue; overload;
    function DoSendMessage(const IOHandler: TIdIOHandler;const Buffer: TIdBytes): Boolean; overload;
    function DoSendResponse(const IOHandler: TIdIOHandler;const Value: TIPCValue;const Status: TIPCResponse): Boolean; overload;
    function ValueToFrame(const MessageID: TMessageID;const Value: TIPCValue;const Command: TIPCCommand;const Broadcast: Boolean): TIdBytes;
    function GetIsMainServer: Boolean;
  protected
    function StartAutoMode: Boolean;
    function StartServerMode: Boolean;
    function StartClientMode: Boolean;
    function SendMessage(const MessageID: TMessageID;const Param: TIPCValue;const Broadcast: Boolean): Boolean; overload;
    function GetMessage(const MessageID: TMessageID;const Param: TIPCValue): TIPCValue; overload;
  public
    constructor Create; overload;
    {$IFDEF MESSAGESERVICE}
    constructor Create(MessageService: TVPLMessageService); overload;
    {$ENDIF}
    destructor Destroy; override;
    function Start(const Mode: TIPCMode): Boolean;
    procedure Stop;
    function Actived: Boolean;
    function SendMessage(const MessageID: TMessageID;const Broadcast: Boolean=False): Boolean; overload;
    function SendMessage(const MessageID: TMessageID;const Params: array of const;const Broadcast: Boolean=False): Boolean; overload;
    function SendMessage<P>(const MessageID: TMessageID;const Param: P;const Broadcast: Boolean=False): Boolean; overload; inline;
    function GetMessage(const MessageID: TMessageID): TIPCValue; overload;inline;
    function GetMessage<V>(const MessageID: TMessageID): V; overload;
    function GetMessage<V>(const MessageID: TMessageID;const Params: array of const): V; overload;
    function GetMessage<P,V>(const MessageID: TMessageID;const Param: P): V; overload;

    function GetMessages(const MessageID: TMessageID;const Param: TIPCValue): TArray<TIPCValue>; overload;
    function GetMessages<V>(const MessageID: TMessageID): TArray<V>; overload;
    function GetMessages<V>(const MessageID: TMessageID;const Params: array of const): TArray<V>; overload;
    function GetMessages<P,V>(const MessageID: TMessageID;const Param: P): TArray<V>; overload;

    property IsMainServer: Boolean read GetIsMainServer;
    property OnGetMessage: TGetMessageEvent read FOnGetMessage write FOnGetMessage;
    property OnSetMessage: TSetMessageEvent read FOnSetMessage write FOnSetMessage;
  end;


procedure NotSupportedType;
function TupleToJSON(const Params: array of const): String; overload;

var
  IPC: TVPLIPC;
  Serializer : TJsonSerializer;
implementation

function RecvBuffer(const IOHandler: TIdIOHandler): TIdBytes;
var
  Size: LongInt;
begin
  Result := nil;
  try
    Size := IOHandler.ReadInt32;
    if Size>0 then
      IOHandler.ReadBytes(Result, Size, False);
  except
    Result := nil;
  end;
end;

function RecvCommand(const IOHandler: TIdIOHandler): TIdBytes;
var
  Head: PIPCCommandHead;
begin
  Result := RecvBuffer(IOHandler);
  if Result<>nil then
  begin
    Head := PIPCCommandHead(@Result[0]);
    if (Head^.FrameType<>TIPCFrameType.ifCommand) or (Length(Result)<Sizeof(TIPCCommandHead)) then
      Result := nil;
  end;
end;

function SendBuffer(const IOHandler: TIdIOHandler;const Buffer: TIdBytes): Boolean;
begin
  try
    try
      IOHandler.Write(Int32(Length(Buffer)));
      IOHandler.WriteBufferOpen;
      IOHandler.Write(Buffer, Length(Buffer));
      IOHandler.WriteBufferFlush;
      Result := True;
    finally
      IOHandler.WriteBufferClose;
    end;
  except
    Result := False;
  end;
end;

function RecvResponse(const IOHandler: TIdIOHandler): TIdBytes;
var
  Head: PIPCResponseHead;
begin
  Result := nil;
  try
    while True do
    begin
      Result := RecvBuffer(IOHandler);
      if (Result<>nil) and (Length(Result)>=Sizeof(TIPCResponseHead)) then
      begin
        Head := PIPCResponseHead(@Result[0]);
        if Head^.FrameType=TIPCFrameType.ifResponse then
        begin
          if Head^.Status=TIPCResponse.IPC_WAIT then
            continue;
        end
        else
          Result := nil;
      end;
      Break;
    end;
  except
    ;
  end;
end;

function RecvResult(const IOHandler: TIdIOHandler): TIPCValue;
var
  R: TIdBytes;
  Head: PIPCResponseHead;
begin
  Result := TIPCValue.Null;
  R := RecvResponse(IOHandler);
  if (R<>nil)and (Length(R)>Sizeof(TIPCResponseHead)) then
  begin
    Head := PIPCResponseHead(@R[0]);
    if Head^.Status=TIPCResponse.IPC_RESULT then
      Result := TIPCValue.FromJSON(IndyTextEncoding_UTF8.GetString(R,Sizeof(TIPCResponseHead),Length(R)-Sizeof(TIPCResponseHead)))
  end
end;

procedure NotSupportedType;
begin
  raise IPCException.Create('Not supported type!');
end;

function VarRecToJSON(const Param: TVarRec): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('Type',Param.VType);
  case Param.VType of
        vtInteger: Result.AddPair('Value',Param.VInteger);
        vtBoolean: Result.AddPair('Value',Param.VBoolean);
           vtChar: Result.AddPair('Value',String(Param.VChar));
       vtExtended: Result.AddPair('Value',Param.VExtended^);
{$IFNDEF NEXTGEN}
         vtString:  Result.AddPair('Value',String(Param.VString^));
{$ENDIF !NEXTGEN}
        vtPointer:  NotSupportedType;
          vtPChar:  NotSupportedType;
{$IFDEF AUTOREFCOUNT}
         vtObject:  NotSupportedType;
{$ELSE}
         vtObject:  Result.AddPair('Value',Serializer.Serialize<TObject>(Param.VObject));
{$ENDIF}
          vtClass:  Result.AddPair('Value',Serializer.Serialize<TClass>(Param.VClass));
       vtWideChar:  Result.AddPair('Value',Param.VWideChar);
      vtPWideChar:  NotSupportedType;
     vtAnsiString:  Result.AddPair('Value',String(AnsiString(Param.VAnsiString)));
       vtCurrency:  Result.AddPair('Value',Param.VCurrency^);
        vtVariant:  Result.AddPair('Value',Serializer.Serialize<Variant>(Param.VVariant^));
      vtInterface:  Result.AddPair('Value',Serializer.Serialize<TObject>(Param.VInterface));
     vtWideString:  Result.AddPair('Value',WideString(Param.VWideString));
          vtInt64:  Result.AddPair('Value',Param.VInt64^);
  vtUnicodeString: Result.AddPair('Value',UnicodeString(Param.VUnicodeString));
    else
      NotSupportedType;
  end;
end;

function JSONToVarRec(const Value: TJSONObject): TVarRec;
begin
  Result.VType := (Value.GetValue('Type') as TJSONNumber).AsInt;
  case Result.VType of
       vtInteger: Result.VInteger := TJSONNumber(Value.GetValue('Value')).AsInt;
       vtBoolean: Result.VBoolean := TJSONBool(Value.GetValue('Value')).AsBoolean;
          vtChar: Result.VChar := AnsiChar(TJSONString(Value.GetValue('Value')).Value.Chars[0]);
      vtExtended: Result.VExtended^ := TJSONNumber(Value.GetValue('Value')).AsDouble;
{$IFNDEF NEXTGEN}
        vtString:  String(Result.VString) := TJSONString(Value.GetValue('Value')).Value;
{$ENDIF !NEXTGEN}
       vtPointer:  NotSupportedType;
         vtPChar:  NotSupportedType;
{$IFDEF AUTOREFCOUNT}
        vtObject:  NotSupportedType;
{$ELSE}
        vtObject: Result.VWideString := PWideString(TJSONString(Value.GetValue('Value')).Value);
{$ENDIF}
         vtClass:  Result.VWideString := PWideString(TJSONString(Value.GetValue('Value')).Value);
      vtWideChar:  Result.VWideChar := TJSONString(Value.GetValue('Value')).Value.Chars[0];
     vtPWideChar:  NotSupportedType;
    vtAnsiString:  Result.VAnsiString := PAnsiString(TJSONString(Value.GetValue('Value')).Value);
      vtCurrency:  Result.VCurrency^ := TJSONNumber(Value.GetValue('Value')).AsDouble;
       vtVariant:  Result.VVariant^ := Serializer.Deserialize<Variant>(TJSONString(Value.GetValue('Value')).Value);
     vtInterface:  Result.VWideString := PWideString(TJSONString(Value.GetValue('Value')).Value);
    vtWideString:  Result.VWideString := PWideString(TJSONString(Value.GetValue('Value')).Value);
         vtInt64:  Result.VInt64^ := TJSONNumber(Value.GetValue('Value')).AsInt64;
 vtUnicodeString:  Result.VUnicodeString := PUnicodeString(TJSONString(Value.GetValue('Value')).Value);
    else
      NotSupportedType;
  end;
end;

function TupleToJSON(const Params: array of const): String; overload;
var
  ParamArray: TJSONArray;
begin
  ParamArray := TJSONArray.Create;
  for var I := Low(Params) to High(Params) do
    ParamArray.AddElement(VarRecToJSON(Params[I]));
  Result := ParamArray.ToString;
end;

function TupleToJSON(const Params: TArray<TVarRec>): String; overload;
var
  ParamArray: TJSONArray;
begin
  ParamArray := TJSONArray.Create;
  for var I := Low(Params) to High(Params) do
    ParamArray.AddElement(VarRecToJSON(Params[I]));
  Result := ParamArray.ToString;
end;

function JSONToTuple(const Json: String): TArray<TVarRec>;
var
  JSONArray: TJSONArray;
begin
  if not Json.IsEmpty then
  begin
    JsonArray := TJSONObject.ParseJSONValue(Json) as TJSONArray;
    SetLength(Result,JSONArray.Count);
    for var I := 0 to JSONArray.Count-1 do
      Result[I] := JSONToVarRec(JSONArray.Items[I] as TJSONObject);
  end
  else
    SetLength(Result,0);
end;

{ TIPCValue }

function TIPCValue.AsBoolean: Boolean;
begin
  Result := vBoolean;
end;

function TIPCValue.AsChar: Char;
begin
  Result := vChar;
end;

function TIPCValue.AsCurrency: Currency;
begin
  Result := vCurrency;
end;

function TIPCValue.AsDate: TDate;
begin
  Result := vDateTime;
end;

function TIPCValue.AsDateTime: TDateTime;
begin
  Result := vDateTime;
end;

function TIPCValue.AsDouble: Double;
begin
  Result := vExtended;
end;

function TIPCValue.AsExtended: Extended;
begin
  Result := vExtended;
end;

function TIPCValue.AsInt16: Int16;
begin
  Result := vInt32;
end;

function TIPCValue.AsInt32: Int32;
begin
  Result := vInt32;
end;

function TIPCValue.AsInt64: Int64;
begin
  Result := vInt64;
end;

function TIPCValue.AsInt8: Int8;
begin
  Result := vInt32;
end;

function TIPCValue.AsInteger: Integer;
begin
  if Sizeof(Integer)=Sizeof(Int32) then
    Result := vInt32
  else
    Result := vInt64
end;

function TIPCValue.AsSingle: Single;
begin
  Result := vExtended;
end;

function TIPCValue.AsString: string;
begin
  Result := _Data;
end;

function TIPCValue.AsTime: TTime;
begin
  Result := vDateTime;
end;

function TIPCValue.AsType<T>: T;
type
  TVPLTuple = TArray<TVarRec>;
var
  Value: TValue;
  ConstArray: TVPLTuple;
begin
  case VType of
    ivObject,
    ivClass,
    ivCustom      :   begin
                          Result := Serializer.Deserialize<T>(AsString);
                          Exit;
                        end;
    ivConstArray  :   begin
                          ConstArray := JSONToConstArray(AsString);
                          TValue.Make<TVPLTuple>(ConstArray,Value);
                          Value.TryAsType<T>(Result);
                          Exit;
                        end;
    ivChar        :     TValue.Make(@vChar,TypeInfo(Char),Value);
    ivBoolean     :     TValue.Make(@vBoolean,TypeInfo(Boolean),Value);
    ivInt8,
    ivInt16,
    ivInt32       :     TValue.Make(@vInt32,TypeInfo(Int32),Value);
    ivInt64       :     TValue.Make(@vInt64,TypeInfo(Int64),Value);
    ivUInt8,
    ivUInt16,
    ivUInt32      :     TValue.Make(@vUInt32,TypeInfo(UInt32),Value);
    ivUInt64      :     TValue.Make(@vUInt64,TypeInfo(UInt64),Value);
    ivSingle,
    ivDouble,
    ivExtended    :     TValue.Make(@vExtended,TypeInfo(Extended),Value);
    ivCurrency    :     TValue.Make(@vCurrency,TypeInfo(Currency),Value);
    ivDate,
    ivTime,
    ivDateTime    :     TValue.Make(@vDateTime,TypeInfo(TDateTime),Value);
    IvString      :     TValue.Make(@_Data,TypeInfo(String),Value);
  else
    NotSupportedType;
  end;
  Value.ExtractRawData(@Result);
end;

function TIPCValue.AsUInt16: UInt16;
begin
  Result := vUInt32;
end;

function TIPCValue.AsUInt32: UInt32;
begin
  Result := vUInt32;
end;

function TIPCValue.AsUInt64: UInt64;
begin
  Result := vUInt64;
end;

function TIPCValue.AsUInt8: UInt8;
begin
  Result := vUint32;
end;

class function TIPCValue.ConstArrayToJSON(const Value: array of const): String;
var
  ValueArray: TJSONArray;
  function VarRecToJSON(const VarRec: TVarRec): TJSONObject;
  begin
    Result := TJSONObject.Create;
    Result.AddPair('Type',VarRec.VType);
    case VarRec.VType of
      vtInteger:    Result.AddPair('Value',VarRec.VInteger);
      vtBoolean:    Result.AddPair('Value',VarRec.VBoolean);
         vtChar:    Result.AddPair('Value',String(VarRec.VChar));
     vtExtended:    Result.AddPair('Value',VarRec.VExtended^);
     vtWideChar:    Result.AddPair('Value',VarRec.VWideChar);
   vtAnsiString:    Result.AddPair('Value',String(AnsiString(VarRec.VAnsiString)));
     vtCurrency:    Result.AddPair('Value',VarRec.VCurrency^);
   vtWideString:    Result.AddPair('Value',WideString(VarRec.VWideString));
        vtInt64:    Result.AddPair('Value',VarRec.VInt64^);
vtUnicodeString:    Result.AddPair('Value',UnicodeString(VarRec.VUnicodeString));
       vtObject:    Result.AddPair('Value',Serializer.Serialize<TObject>(VarRec.VObject));
        vtClass:    Result.AddPair('Value',Serializer.Serialize<TClass>(VarRec.VClass));
    else
      NotSupportedType;
    end;
  end;
begin
  ValueArray := TJSONArray.Create;
  try
    for var I := Low(Value) to High(Value) do
      ValueArray.Add(VarRecToJSON(Value[I]));
    Result := ValueArray.ToJSON;
  finally
    FreeAndNil(ValueArray);
  end;
end;

class function TIPCValue.From(const Value: array of const): TIPCValue;
begin
  Result.VType := ivConstArray;
  Result._Data := ConstArrayToJSON(Value);
end;

class function TIPCValue.From(const Value: Int64): TIPCValue;
begin
  Result := Value;
end;

class function TIPCValue.From(const Value: UInt8): TIPCValue;
begin
  Result := Value;
end;

class function TIPCValue.From(const Value: UInt16): TIPCValue;
begin
  Result := Value;
end;

class function TIPCValue.From(const Value: UInt32): TIPCValue;
begin
  Result := Value;
end;

class function TIPCValue.From(const Value: Int32): TIPCValue;
begin
  Result := Value;
end;

class function TIPCValue.From(const Value: Char): TIPCValue;
begin
  Result := Value;
end;

class function TIPCValue.From(const Value: Boolean): TIPCValue;
begin
  Result := Value;
end;

class function TIPCValue.From(const Value: Int8): TIPCValue;
begin
  Result := Value;
end;

class function TIPCValue.From(const Value: Int16): TIPCValue;
begin
  Result := Value;
end;

class function TIPCValue.From(const Value: UInt64): TIPCValue;
begin
  Result := Value;
end;

class function TIPCValue.From(const Value: TDate): TIPCValue;
begin
  Result := Value;
end;

class function TIPCValue.From(const Value: TTime): TIPCValue;
begin
  Result := Value;
end;

class function TIPCValue.From(const Value: TObject): TIPCValue;
begin
  Result := Value;
end;

class function TIPCValue.From(const Value: TClass): TIPCValue;
begin
  Result := Value;
end;

class function TIPCValue.From(const Value: String): TIPCValue;
begin
  Result := Value;
end;

class function TIPCValue.From(const Value: Single): TIPCValue;
begin
  Result := Value;
end;

class function TIPCValue.From(const Value: Double): TIPCValue;
begin
  Result := Value;
end;

class function TIPCValue.From(const Value: Extended): TIPCValue;
begin
  Result := Value;
end;

class function TIPCValue.From(const Value: Currency): TIPCValue;
begin
  Result := Value;
end;

class function TIPCValue.From<T>(const Value: T): TIPCValue;
var
  Pt: PTypeInfo;
  TmpValue: TValue;
begin
  Pt := TypeInfo(T);
  case Pt^.Kind of
    tkInteger:
      case GetTypeData(Pt)^.OrdType of
        otSByte: Result.VType := ivInt8;
        otSWord: Result.VType := ivInt16;
        otSLong: Result.VType := ivInt32;
        otUByte: Result.VType := ivUInt8;
        otUWord: Result.VType := ivUInt16;
        otULong: Result.VType := ivUInt32;
        else
          NotSupportedType;
      end;
    tkChar: Result.VType := ivChar;
    tkFloat:
      case GetTypeData(Pt)^.FloatType of
        ftSingle: Result.VType := ivSingle;
        ftDouble: Result.VType := ivDouble;
        ftExtended: Result.VType := ivExtended;
        ftComp: Result.VType := ivDouble;
        ftCurr: Result.VType := ivCurrency;
        else
          NotSupportedType;
      end;
    tkString, tkLString, tkUString, tkWString: begin
        Result.VType := ivString;
        TmpValue := TValue.From<T>(Value);
        TmpValue.ExtractRawData(@Result._Data);
        Exit;
    end;
    tkWChar: Result.VType := ivChar;
    tkInt64: begin
      with GetTypeData(Pt)^ do
        if MinInt64Value > MaxInt64Value then
          Result.VType := ivUInt64
        else
          Result.VType := ivInt64;
    end
    else
    begin
      Result.VType := ivCustom;
      Result._Data := Serializer.Serialize<T>(Value);
      Exit;
    end;
  end;
  TmpValue := TValue.From<T>(Value);
  TmpValue.ExtractRawDataNoCopy(@Result.vInt32);
end;

class function TIPCValue.FromJSON(const Value: String): TIPCValue;
var
  ValueStr: String;
  JSONValue: TJSONObject;
begin
  JSONValue := TJSONObject.ParseJSONValue(Value) as TJSONObject;
  if JSONValue<>nil then
  try
    Result.VType := TJSONNumber(JSONValue.GetValue('Type')).AsInt;
    ValueStr := TJSONString(JSONValue.GetValue('Value')).Value;
    case Result.VType of
      ivChar        :     Result.vChar := ValueStr.Chars[0];
      ivBoolean     :     Result.vBoolean := iif(ValueStr=JSONBoolStrs[True],True,False);
      ivInt8,
      ivInt16,
      ivInt32       :     Result.vInt32 := StrToInt(ValueStr);
      ivInt64       :     Result.vInt64 := StrToInt64(ValueStr);
      ivUInt8,
      ivUInt16,
      ivUInt32      :     Result.vUInt32 := StrToUInt(ValueStr);
      ivUInt64      :     Result.vUInt64 := StrToUInt64(ValueStr);
      ivSingle,
      ivDouble,
      ivExtended    :     Result.vExtended := StrToFloat(ValueStr);
      ivCurrency    :     Result.vCurrency := StrToCurr(ValueStr);
      ivDate,
      ivTime,
      ivDateTime    :     Result.vDateTime := Serializer.Deserialize<TDateTime>(ValueStr);
      ivConstArray,
      ivString,
      ivObject,
      ivClass,
      ivCustom      :     Result._Data :=  ValueStr;
      else
        NotSupportedType;
    end;
  finally
    FreeAndNil(JSONValue);
  end
  else
    Result := TIPCValue.Null;
end;

class operator TIPCValue.Implicit(const Value: Int16): TIPCValue;
begin
  Result.VType := ivInt16;
  Result.VInt32 := Value;
end;

class operator TIPCValue.Implicit(const Value: Int32): TIPCValue;
begin
  Result.VType := ivInt32;
  Result.VInt32 := Value;
end;

class operator TIPCValue.Implicit(const Value: Int8): TIPCValue;
begin
  Result.VType := ivInt8;
  Result.VInt32 := Value;
end;

class operator TIPCValue.Implicit(const Value: Boolean): TIPCValue;
begin
  Result.VType := ivBoolean;
  Result.VBoolean := Value;
end;

class operator TIPCValue.Implicit(const Value: Char): TIPCValue;
begin
  Result.VType := ivChar;
  Result.VChar := Value;
end;

class operator TIPCValue.Implicit(const Value: TDate): TIPCValue;
begin
  Result.VType := ivDate;
  Result.VDateTime :=  Value;
end;

class operator TIPCValue.Implicit(const Value: String): TIPCValue;
begin
  Result.VType := ivString;
  Result._Data := Value;
end;

class operator TIPCValue.Implicit(const Value: Currency): TIPCValue;
begin
  Result.VType := ivCurrency;
  Result.VCurrency := Value;
end;

class operator TIPCValue.Implicit(const Value: TTime): TIPCValue;
begin
  Result.VType := ivTime;
  Result.VDateTime := Value;
end;

class operator TIPCValue.Implicit(const Value: TClass): TIPCValue;
begin
  Result.VType := ivClass;
  Result._Data := Serializer.Serialize<TClass>(Value);
end;

function TIPCValue.IsNull: Boolean;
begin
  Result := VType = ivNull;
end;

class function TIPCValue.JSONToConstArray(const Value: String): TArray<TVarRec>;
  function JSONToVarRec(const Value: TJSONObject): TVarRec;
  begin
    Result.VType := (Value.GetValue('Type') as TJSONNumber).AsInt;
    case Result.VType of
       vtInteger:   Result.VInteger := TJSONNumber(Value.GetValue('Value')).AsInt;
       vtBoolean:   Result.VBoolean := TJSONBool(Value.GetValue('Value')).AsBoolean;
          vtChar:   Result.VChar := AnsiChar(TJSONString(Value.GetValue('Value')).Value.Chars[0]);
      vtExtended:   Result.VExtended^ := TJSONNumber(Value.GetValue('Value')).AsDouble;
        vtObject:   Result.VWideString := PWideString(TJSONString(Value.GetValue('Value')).Value);
         vtClass:   Result.VWideString := PWideString(TJSONString(Value.GetValue('Value')).Value);
      vtWideChar:   Result.VWideChar := TJSONString(Value.GetValue('Value')).Value.Chars[0];
    vtAnsiString:   Result.VAnsiString := PAnsiString(TJSONString(Value.GetValue('Value')).Value);
      vtCurrency:   Result.VCurrency^ := TJSONNumber(Value.GetValue('Value')).AsDouble;
    vtWideString:   Result.VWideString := PWideString(TJSONString(Value.GetValue('Value')).Value);
         vtInt64:   Result.VInt64^ := TJSONNumber(Value.GetValue('Value')).AsInt64;
 vtUnicodeString:   Result.VUnicodeString := PUnicodeString(TJSONString(Value.GetValue('Value')).Value);
    else
      NotSupportedType;
  end;
end;

var
  JSONArray: TJSONArray;
begin
  if Value<>'' then
  begin
    JSONArray := TJSONObject.ParseJSONValue(Value) as TJSONArray;
    if JSONArray<>nil then
    begin
      try
        Setlength(Result,JSONArray.Count);
        for var I := 0 to JSONArray.Count-1 do
          Result[I] := JSONToVarRec(JSONArray.Items[I] as TJSONObject);
      finally
        FreeAndNil(JSONArray);
      end;
    end
    else
      SetLength(Result,0);
  end
  else
    SetLength(Result,0);
end;

class function TIPCValue.Null: TIPCValue;
begin
  Result.VType := ivNull;
end;

function TIPCValue.ToJSON: String;
var
  Value: String;
  JSON: TJSONObject;
begin
  case VType of
   ivChar        :     Value := vChar;
   ivBoolean     :     Value := JSONBoolStrs[vBoolean];
   ivInt8        :     Value := IntToStr(AsInt8);
   ivInt16       :     Value := IntToStr(AsInt16);
   ivInt32       :     Value := IntToStr(AsInt32);
   ivInt64       :     Value := IntToStr(AsInt64);
   ivUInt8       :     Value := UIntToStr(AsUInt8);
   ivUInt16      :     Value := UIntToStr(AsUInt16);
   ivUInt32      :     Value := UIntToStr(AsUInt32);
   ivUInt64      :     Value := UIntToStr(AsUInt64);
   ivSingle      :     Value := FloatToStr(AsSingle);
   ivDouble      :     Value := FloatToStr(AsDouble);
   ivExtended    :     Value := FloatToStr(AsExtended);
   ivCurrency    :     Value := CurrToStr(AsCurrency);
   IvString      :     Value := AsString;
   ivDate        :     Value := Serializer.Serialize<TDate>(AsDate);
   ivTime        :     Value := Serializer.Serialize<TDate>(AsTime);
   ivDateTime    :     Value := Serializer.Serialize<TDate>(AsDateTime);
   ivConstArray  :     Value := AsString;
   ivObject      :     Value := AsString;
   ivClass       :     Value := AsString;
   ivCustom      :     Value := AsString;
   else
      NotSupportedType;
  end;
  JSON := TJSONObject.Create;
  try
    JSON.AddPair('Type',VType);
    JSON.AddPair('Value',Value);
    Result := JSON.ToJSON;
  finally
    FreeAndNil(JSON);
  end;
end;

class operator TIPCValue.Implicit(const Value: TObject): TIPCValue;
begin
  Result.VType := ivObject;
  Result._Data := Serializer.Serialize<TObject>(Value);
end;

class operator TIPCValue.Implicit(const Value: TDateTime): TIPCValue;
begin
  Result.VType := ivDateTime;
  Result.VDateTime := Value;
end;

class operator TIPCValue.Implicit(const Value: Extended): TIPCValue;
begin
  Result.VType := ivExtended;
  Result.VExtended := Value;
end;

class operator TIPCValue.Implicit(const Value: UInt16): TIPCValue;
begin
  Result.VType := ivUInt16;
  Result.VUInt32 := Value;
end;

class operator TIPCValue.Implicit(const Value: UInt8): TIPCValue;
begin
  Result.VType := ivUInt8;
  Result.VUInt32 := Value;
end;

class operator TIPCValue.Implicit(const Value: Int64): TIPCValue;
begin
  Result.VType := ivInt64;
  Result.VInt64 := Value;
end;

class operator TIPCValue.Implicit(const Value: UInt32): TIPCValue;
begin
  Result.VType := ivUInt32;
  Result.VUInt32 := Value;
end;

class operator TIPCValue.Implicit(const Value: Double): TIPCValue;
begin
  Result.VType := ivDouble;
  Result.VExtended := Value;
end;

class operator TIPCValue.Implicit(const Value: Single): TIPCValue;
begin
  Result.VType := ivSingle;
  Result.VExtended := Value;
end;

class operator TIPCValue.Implicit(const Value: UInt64): TIPCValue;
begin
  Result.VType := ivUInt64;
  Result.VUInt64 := Value;
end;

{ TVPLIPC }

constructor TVPLIPC.Create;
var
  SocketHandle: TIdSocketHandle;
begin
  FMode := TIPCMode.imUnkown;
  FClientServer := TIdTCPServer.Create(nil);
  FClientServer.OnExecute := DoClientServerExecute;
  FClientServer.OnDisconnect := DoClientServerDisconnect;
  SocketHandle := FClientServer.Bindings.Add;
  SocketHandle.Port := 0;
  SocketHandle.IP := LOCAL_IP;
end;

{$IFDEF MESSAGESERVICE}
function TVPLIPC.ConnectToMainServer: Boolean;
var
  Port: Word;
begin
  Result := False;
  Assert(FClientServer.Active and (FMainServer=nil));
  Port := GetServerPort;
  if Port>0 then
    Result := ConnectToMainServer(Port);
end;

function TVPLIPC.ConnectToMainServer(const Port: word): Boolean;
var
  Param: TIdBytes;
begin
  Result := False;
  if FClient=nil then
    FClient := TIdTCPClient.Create(nil)
  else
  begin
    if FClient.Connected then
    try
      FClient.Disconnect;
    except
      ;
    end;
  end;
  try
    FClient.Connect(LOCAL_IP,Port);
    Param := ValueToFrame(0,TIPCValue.From([FClientServer.Bindings[0].Port,ord(FMode)]),TIPCCommand.icRegister,False);
    Result := DoSendMessage(FClient.IOHandler,Param);
    if not Result then
      FreeAndNil(FClient);
  except
    FreeAndNil(FClient);
  end;
end;

constructor TVPLIPC.Create(MessageService: TVPLMessageService);
begin
  Create;
  FMessageService := MessageService;
end;

{$ENDIF}

destructor TVPLIPC.Destroy;
begin
  Stop;
  if FClient<>nil then
    FreeAndNil(FClient);
  FreeAndNil(FClientServer);
  inherited;
end;

function TVPLIPC.DoSendMessage(const IOHandler: TIdIOHandler;const Buffer: TIdBytes): Boolean;
var
  Resp: TIdBytes;
  Head: PIPCResponseHead;
begin
  Result := SendBuffer(IOHandler,Buffer);
  if Result then
  begin
    Resp := RecvResponse(IOHandler);
    if Resp<>nil then
    begin
      Head := PIPCResponseHead(@Resp[0]);
      Result := Head^.Status= TIPCResponse.IPC_OK;
    end
    else
      Result := False;
  end;
end;

function TVPLIPC.DoSendResponse(const IOHandler: TIdIOHandler; const Value: TIPCValue; const Status: TIPCResponse): Boolean;
var
  Buffer: TIdBytes;
  ParamBytes: TBytes;
  Head: PIPCResponseHead;
begin
  if not Value.IsNull then
  begin
    ParamBytes := TEncoding.UTF8.GetBytes(Value.ToJSON);
    SetLength(Buffer,Length(ParamBytes)+Sizeof(TIPCResponseHead));
    Move(ParamBytes[0],Buffer[Sizeof(TIPCResponseHead)],Length(ParamBytes));
  end
  else
    SetLength(Buffer,Sizeof(TIPCResponseHead));
  Head := PIPCResponseHead(@Buffer[0]);
  Head.FrameType := TIPCFrameType.ifResponse;
  Head^.Status := Status;
  Result := SendBuffer(IOHandler,Buffer);
end;

procedure TVPLIPC.DoClientModeExecute(AContext: TIdContext;const AData: TIdBytes);
var
  Ret: TIPCValue;
  Param: TIPCValue;
  Head: PIPCCommandHead;
begin
  Head := PIPCCommandHead(@AData[0]);
  if Length(AData)>Sizeof(TIPCCommandHead) then
    Param := TIPCValue.FromJSON(IndyTextEncoding_UTF8.GetString(AData,Sizeof(TIPCCommandHead),Length(AData)-Sizeof(TIPCCommandHead)))
  else
    Param := TIPCValue.Null;
  case Head^.Command of
          TIPCCommand.icGet:begin
                            {$IFDEF MESSAGESERVICE}
                              Ret := MessageService.GetMessage<TIPCValue,TIPCValue>(nil,Head^.MessageID,Param);
                            {$ELSE}
                              if Assigned(FOnGetMessage) then
                                FOnGetMessage(Head^.MessageID,Param,Ret);
                            {$ENDIF}
                              DoSendResponse(AContext.Connection.IOHandler,Ret,TIPCResponse.IPC_RESULT);
                            end;
          TIPCCommand.icSet:begin
                            {$IFDEF MESSAGESERVICE}
                              MessageService.SendMessage<TIPCValue>(nil,Head^.MessageID,Param);
                            {$ELSE}
                              if Assigned(FOnSetMessage) then
                                FOnSetMessage(Head^.MessageID,Param);
                            {$ENDIF}
                              if Head^.Broadcast and IsMainServer then
                                SendMessage(Head^.MessageID,Param,False);
                              DoSendResponse(AContext.Connection.IOHandler,TIPCValue.Null,TIPCResponse.IPC_OK);
                            end;
   TIPCCommand.icMainServer:begin
                              if FMode=TIPCMode.imAuto then
                              begin
                                if StartMainServer then
                                begin
                                  DoSendResponse(AContext.Connection.IOHandler,TIPCValue.Null,TIPCResponse.IPC_OK);
                                  try
                                    FreeAndNil(FClient);
                                  except
                                    ;
                                  end;
                                end
                                else
                                  DoSendResponse(AContext.Connection.IOHandler,TIPCValue.Null,TIPCResponse.IPC_ERROR);
                              end
                              else
                                DoSendResponse(AContext.Connection.IOHandler,TIPCValue.Null,TIPCResponse.IPC_NOTSUPPORT)
                            end;
 TIPCCommand.icSwitchServer:begin
                              if not Param.IsNull then
                              begin
                                if ConnectToMainServer(Param.AsUInt16) then
                                  DoSendResponse(AContext.Connection.IOHandler,TIPCValue.Null,TIPCResponse.IPC_OK)
                                else
                                  DoSendResponse(AContext.Connection.IOHandler,TIPCValue.Null,TIPCResponse.IPC_ERROR)
                              end
                              else
                                DoSendResponse(AContext.Connection.IOHandler,TIPCValue.Null,TIPCResponse.IPC_ERROR);
                            end;
 TIPCCommand.icDisconnect:begin
                            DoSendResponse(AContext.Connection.IOHandler,TIPCValue.Null,TIPCResponse.IPC_OK);
                            Stop;
                          end;

     else
       DoSendResponse(AContext.Connection.IOHandler,TIPCValue.Null,TIPCResponse.IPC_NOTSUPPORT)
  end;
end;

function TVPLIPC.GetServerPort: Word;
var
  Ret: TIPCValue;
  Param: TIdBytes;
  TmpClient: TIdTCPClient;
begin
  Result := 0;
  TmpClient := TIdTCPClient.Create(nil);
  try
    TmpClient.Connect(LOCAL_IP,IPC_PORT);
    Param := ValueToFrame(0,TIPCValue.Null,TIPCCommand.icQuery,False);
    Ret := DoGetMessage(TmpClient.IOHandler,Param);
    if not Ret.IsNull then
      Result := Ret.AsUInt16;
    TmpClient.Disconnect;
  finally
    FreeAndNil(TmpClient);
  end;
end;

procedure TVPLIPC.IPCNotStart;
begin
  raise IPCException.Create('IPC not Start!');
end;

function TVPLIPC.GetIsMainServer: Boolean;
begin
  Result := (FMainServer<>nil) and FMainServer.Active;
end;

function TVPLIPC.GetMessage(const MessageID: TMessageID): TIPCValue;
begin
  Result := GetMessage(MessageID,TIPCValue.Null);
end;

procedure TVPLIPC.DoServerModeExecute(AContext: TIdContext;const AData: TIdBytes);
var
  Ret: TIPCValue;
  Param: TIPCValue;
  Head: PIPCCommandHead;
  RegData: TArray<TVarRec>;
  TmpClient: TIdTCPClient;
begin
  Head := PIPCCommandHead(@AData[0]);
  if Length(AData)>Sizeof(TIPCCommandHead) then
    Param := TIPCValue.FromJSON(IndyTextEncoding_UTF8.GetString(AData,Sizeof(TIPCCommandHead),Length(AData)-Sizeof(TIPCCommandHead)))
  else
    Param := TIPCValue.Null;
  case Head^.Command of
        TIPCCommand.icGet:begin
                            {$IFDEF MESSAGESERVICE}
                            Ret := MessageService.GetMessage<TIPCValue,TIPCValue>(nil,Head^.MessageID,Param);
                            {$ELSE}
                            if Assigned(FOnGetMessage) then
                              FOnGetMessage(Head^.MessageID,Param,Ret);
                            {$ENDIF}
                            DoSendResponse(AContext.Connection.IOHandler,Ret,TIPCResponse.IPC_RESULT);
                          end;
        TIPCCommand.icSet:begin
                          {$IFDEF MESSAGESERVICE}
                            MessageService.SendMessage<TIPCValue>(nil,Head^.MessageID,Param);
                          {$ELSE}
                            if Assigned(FOnSetMessage) then
                              FOnSetMessage(Head^.MessageID,Param);
                          {$ENDIF}
                            if Head^.Broadcast then
                              SendMessage(Head^.MessageID,Param,False);
                            DoSendResponse(AContext.Connection.IOHandler,TIPCValue.Null,TIPCResponse.IPC_OK);
                          end;
   TIPCCommand.icRegister:begin
                            if not Param.IsNull then
                            begin
                              RegData := Param.AsType<TArray<TVarRec>>;
                              TmpClient := TIdTCPClient.Create(nil);
                              try
                                TmpClient.Connect(LOCAL_IP,RegData[0].VInteger);
                                TmpClient.Tag := RegData[1].VInteger;
                                AContext.Data := TmpClient;
                                DoSendResponse(AContext.Connection.IOHandler,TIPCValue.Null,TIPCResponse.IPC_OK);
                              except
                                FreeAndNil(TmpClient);
                                DoSendResponse(AContext.Connection.IOHandler,TIPCValue.Null,TIPCResponse.IPC_ERROR);
                              end;
                            end
                            else
                              DoSendResponse(AContext.Connection.IOHandler,TIPCValue.Null,TIPCResponse.IPC_NOTSUPPORT);
                          end;
 TIPCCommand.icUnRegister:begin
                            if AContext.Data<>nil then
                            begin
                              TmpClient := TIdTCPClient(AContext.Data);
                              try
                                AContext.Data := nil;
                                DoSendResponse(AContext.Connection.IOHandler,TIPCValue.Null,TIPCResponse.IPC_OK);
                              finally
                                FreeAndNil(TmpClient);
                              end;
                            end;
                          end;
    else
      DoSendResponse(AContext.Connection.IOHandler,TIPCValue.Null,TIPCResponse.IPC_NOTSUPPORT);
  end;
end;

procedure TVPLIPC.DoClientServerDisconnect(AContext: TIdContext);
var
  Tmp: TObject;
begin
  if AContext.Data<>nil then
  begin
    Tmp := AContext.Data;
    AContext.Data := nil;
    FreeAndNil(Tmp);
  end;
end;

procedure TVPLIPC.DoClientServerExecute(AContext: TIdContext);
var
  Buffer: TIdBytes;
begin
  Buffer := RecvCommand(AContext.Connection.IOHandler);
  if Buffer<>nil then
  begin
    if IsMainServer then
      DoServerModeExecute(AContext,Buffer)
    else
      DoClientModeExecute(AContext,Buffer);
  end;
end;

function TVPLIPC.DoGetMessage(const IOHandler: TIdIOHandler; const Buffer: TIdBytes): TIPCValue;
var
  Resp: TIdBytes;
  Head: PIPCResponseHead;
begin
  Result := TIPCValue.Null;
  if SendBuffer(IOHandler,Buffer) then
  begin
    Resp := RecvResponse(IOHandler);
    if (Resp<>nil) and (Length(Resp)>Sizeof(TIPCResponseHead)) then
    begin
      Head := PIPCResponseHead(@Resp[0]);
      if Head^.Status=TIPCResponse.IPC_RESULT then
        Result := TIPCValue.FromJSON(IndyTextEncoding_UTF8.GetString(Resp,Sizeof(TIPCResponseHead),Length(Resp)-Sizeof(TIPCResponseHead)))
    end;
  end;
end;

procedure TVPLIPC.DoMainServerExecute(AContext: TIdContext);
var
  Buffer: TIdBytes;
begin
  if FClientServer.Active then
  begin
    Buffer := RecvCommand(AContext.Connection.IOHandler);
    if Buffer<>nil then
    begin
      if PIPCCommandHead(@Buffer[0])^.Command=TIPCCommand.icQuery then
        DoSendResponse(AContext.Connection.IOHandler,TIPCValue.From(FClientServer.Bindings[0].Port),TIPCResponse.IPC_RESULT);
    end;
  end
  else
    DoSendResponse(AContext.Connection.IOHandler,TIPCValue.Null,TIPCResponse.IPC_ERROR);
end;

function TVPLIPC.GetMessage(const MessageID: TMessageID; const Param: TIPCValue): TIPCValue;
var
  List: TList;
  Buffer: TIdBytes;
begin
  Result := TIPCValue.Null;

  if not Actived then IPCNotStart;

  Buffer := ValueToFrame(MessageID,Param,TIPCCommand.icGet,False);
  if IsMainServer then
  begin
    List := FClientServer.Contexts.LockList;
    try
      for var I := 0 to List.Count-1 do
      begin
        if (TIdContext(List[I]).Data<>nil) then
        begin
          Result := DoGetMessage(TIdTCPClient(TIdContext(List[I]).Data).IOHandler,Buffer);
          if not Result.IsNull then
            Break;
        end;
      end;
    finally
      FClientServer.Contexts.UnlockList;
    end;
  end
  else
    Result := DoGetMessage(FClient.IOHandler,Buffer);
end;

function TVPLIPC.Actived: Boolean;
begin
  Result := FClientServer.Active;
end;

function TVPLIPC.SendMessage(const MessageID: TMessageID; const Param: TIPCValue;const Broadcast: Boolean): Boolean;
var
  List: TList;
  Buffer: TIdBytes;
begin
  Result := False;
  if not Actived then IPCNotStart;

  Buffer := ValueToFrame(MessageID,Param,TIPCCommand.icSet,Broadcast);
  if IsMainServer then
  begin
    List := FClientServer.Contexts.LockList;
    try
      for var I := 0 to List.Count-1 do
      begin
        if (TIdContext(List[I]).Data<>nil) then
          Result := DoSendMessage(TIdTCPClient(TIdContext(List[I]).Data).IOHandler,Buffer);
      end;
    finally
      FClientServer.Contexts.UnlockList;
    end;
  end
  else
    Result := DoSendMessage(FClient.IOHandler,Buffer);
end;

function TVPLIPC.SendMessage(const MessageID: TMessageID;const Broadcast: Boolean=False): Boolean;
begin
  Result := SendMessage(MessageID,TIPCValue.Null,Broadcast);
end;

function TVPLIPC.SendMessage(const MessageID: TMessageID; const Params: array of const;const Broadcast: Boolean=False): Boolean;
begin
  Result := SendMessage(MessageID,TIPCValue.From(Params),Broadcast);
end;

function TVPLIPC.Start(const Mode: TIPCMode): Boolean;
begin
  if FMode<>Mode then
    Stop;
  Result := Actived;
  if not Result then
  begin
    FMode := Mode;
    case FMode of
      imAuto: Result := StartAutoMode;
      imServer: Result := StartServerMode;
      imClient: Result := StartClientMode;
    end;
  end;
end;

function TVPLIPC.StartAutoMode: Boolean;
begin
  Result := StartMainServer;
  if Result then
    Result := StartServerMode
  else
    Result := StartClientMode;
end;

function TVPLIPC.StartMainServer: Boolean;
var
  SocketHandle: TIdSocketHandle;
begin
  if FMainServer=nil then
  begin
    FMainServer := TIdTCPServer.Create(nil);
    FMainServer.OnExecute := DoMainServerExecute;
    SocketHandle := FMainServer.Bindings.Add;
    SocketHandle.Port := IPC_PORT;
    SocketHandle.IP := LOCAL_IP;
  end;
  Result := FMainServer.Active;
  if not Result then
  try
    FMainServer.Active := True;
    Result := FMainServer.Active;
  except
    FreeAndNil(FMainServer);
  end;
end;

function TVPLIPC.StartClientMode: Boolean;
begin
  try
    FClientServer.Active := True;
    if not ConnectToMainServer then
      Stop;
    Result := FClientServer.Active;
  except
    Stop;
    Result := False;
  end;
end;

function TVPLIPC.StartServerMode: Boolean;
begin
  Result := StartMainServer;
  if Result then
  begin
    FClientServer.Active := True;
    Result := True;
  end;
end;

{ TVPLIPC }
procedure TVPLIPC.Stop;
var
  List: TList;
  MainServer: Boolean;
  Buffer: TIdBytes;
  NewServerPort: Word;
  TmpClient: TIdTCPClient;
  procedure SwitchServer;
  begin
    NewServerPort := 0;
    List := FClientServer.Contexts.LockList;
    try
      if List.Count>0 then
      begin
        Buffer := ValueToFrame(0,TIPCValue.Null,TIPCCommand.icMainServer,True);
        for var I := 0 to List.Count-1 do
        begin
          if TIdContext(List[I]).Data<>nil then
          begin
            TmpClient := TIdTCPClient(TIdContext(List[I]).Data);
            if TmpClient.Tag=ord(TIPCMode.imAuto) then
            begin
              if DoSendMessage(TmpClient.IOHandler,Buffer) then
              begin
                NewServerPort := TmpClient.Port;
                Break;
              end;
            end;
          end;
        end;
      end;
    finally
      FClientServer.Contexts.UnlockList;
    end;
 end;
begin
  FMode := TIPCMode.imUnkown;

  MainServer := FMainServer<>nil;
  try
    if FMainServer<>nil then
      FMainServer.Active := False;
    if FClient<>nil then
    begin
      if FClient.Connected then
      begin
        Buffer := ValueToFrame(0,TIPCValue.Null,TIPCCommand.icUnRegister,False);
        DoSendMessage(FClient.IOHandler,Buffer);
        FClient.Disconnect;
      end;
    end;
    if MainServer and FClientServer.Active then
    begin
      SwitchServer;
      List := FClientServer.Contexts.LockList;
      try
        if NewServerPort>0 then
          Buffer := ValueToFrame(0,TIPCValue.From(NewServerPort),TIPCCommand.icSwitchServer,False)
        else
          Buffer := ValueToFrame(0,TIPCValue.Null,TIPCCommand.icDisconnect,False);
        for var I := List.Count-1 downto 0 do
        begin
          if TIdContext(List[I]).Data<>nil then
          begin
            TmpClient := TIdTCPClient(TIdContext(List[I]).Data);
            try
              TIdContext(List[I]).Data := nil;
              try
                if TmpClient.Port<>NewServerPort then
                  DoSendMessage(TmpClient.IOHandler,Buffer);
                TmpClient.Disconnect;
              except
                ;
              end;
            finally
              FreeAndNil(TmpClient);
            end;
          end;
        end;
      finally
        FClientServer.Contexts.UnlockList;
      end;
    end;
  finally
    if FMainServer<>nil then
      FreeAndNil(FMainServer);
    if FClient<>nil then
      FreeAndNil(FClient);
    FClientServer.Active := False;
  end;
end;

function TVPLIPC.ValueToFrame(const MessageID: TMessageID;const Value: TIPCValue;const Command: TIPCCommand;const Broadcast: boolean): TIdBytes;
var
  ParamBytes: TBytes;
  Head: PIPCCommandHead;
begin
  if not Value.IsNull then
  begin
    ParamBytes := TEncoding.UTF8.GetBytes(Value.ToJSON);
    SetLength(Result,Length(ParamBytes)+Sizeof(TIPCCommandHead));
    Move(ParamBytes[0],Result[Sizeof(TIPCCommandHead)],Length(ParamBytes));
  end
  else
    SetLength(Result,Sizeof(TIPCCommandHead));
  Head := PIPCCommandHead(@Result[0]);
  Head^.FrameType := TIPCFrameType.ifCommand;
  Head^.MessageID := MessageID;
  Head^.Command := Command;
  Head^.Broadcast := Broadcast;
end;

function TVPLIPC.GetMessage<P, V>(const MessageID: TMessageID; const Param: P): V;
begin
  Result := GetMessage(MessageID,TIPCValue.From<P>(Param)).AsType<V>;
end;

function TVPLIPC.GetMessage<V>(const MessageID: TMessageID): V;
begin
  Result := GetMessage(MessageID,TIPCValue.Null).AsType<V>;
end;

function TVPLIPC.GetMessage<V>(const MessageID: TMessageID; const Params: array of const): V;
begin
  Result := GetMessage(MessageID,TIPCValue.From(Params)).AsType<V>;
end;

function TVPLIPC.GetMessages(const MessageID: TMessageID; const Param: TIPCValue): TArray<TIPCValue>;
var
  List: TList;
  Ret: TIPCValue;
  Buffer: TIdBytes;
  ResultList: TList<TIPCValue>;
begin
  SetLength(Result,0);
  Buffer := ValueToFrame(MessageID,Param,TIPCCommand.icGet,False);
  if IsMainServer then
  begin
    ResultList := TList<TIPCValue>.Create;
    try
      List := FClientServer.Contexts.LockList;
      try
        for var I := 0 to List.Count-1 do
        begin
          if (TIdContext(List[I]).Data<>nil) then
          begin
            Ret := DoGetMessage(TIdTCPClient(TIdContext(List[I]).Data).IOHandler,Buffer);
            if not Ret.IsNull then
              ResultList.Add(Ret);
          end;
        end;
      finally
        FClientServer.Contexts.UnlockList;
      end;
      if ResultList.Count>0 then
        Result := ResultList.ToArray
    finally
      FreeAndNil(ResultList);
    end;
  end
  else
  begin
    Ret := DoGetMessage(FClient.IOHandler,Buffer);
    if not Ret.IsNull then
    begin
      SetLength(Result,1);
      Result[0] := Ret;
    end
  end;
end;

function TVPLIPC.GetMessages<P, V>(const MessageID: TMessageID; const Param: P): TArray<V>;
var
  List: TArray<TIPCValue>;
begin
  List := GetMessages(MessageID,TIPCValue.From<P>(Param));
  SetLength(Result,Length(List));
  for var I := Low(List) to High(List) do
    Result[I] := List[I].AsType<V>;
end;

function TVPLIPC.GetMessages<V>(const MessageID: TMessageID): TArray<V>;
var
  List: TArray<TIPCValue>;
begin
  List := GetMessages(MessageID,TIPCValue.Null);
  SetLength(Result,Length(List));
  for var I := Low(List) to High(List) do
    Result[I] := List[I].AsType<V>;
end;

function TVPLIPC.GetMessages<V>(const MessageID: TMessageID; const Params: array of const): TArray<V>;
var
  List: TArray<TIPCValue>;
begin
  List := GetMessages(MessageID,TIPCValue.From(Params));
  SetLength(Result,Length(List));
  for var I := Low(List) to High(List) do
    Result[I] := List[I].AsType<V>;
end;

function TVPLIPC.SendMessage<P>(const MessageID: TMessageID; const Param: P;const Broadcast: Boolean): Boolean;
begin
  Result := SendMessage(MessageID,TIPCValue.From<P>(Param),Broadcast);
end;

initialization
  Serializer := TJsonSerializer.Create;
{$IFDEF MESSAGESERVICE}
  IPC := TVPLIPC.Create(MessageService);
{$ELSE}
  IPC := TVPLIPC.Create;
{$ENDIF}
  //IPC.Start;
finalization
  FreeAndNil(IPC);
  FreeAndNil(Serializer);
end.
