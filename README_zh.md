# MessageService
*[English](README.md)*
## 简介
**MessageService**是一个适用于Delphi的消息发布订阅系统,与其他消息系统不同,简单的消息不需要定义类,接口.**MessageService**是以消息ID为基础,借助泛型实现了更加自由，灵活，方便的消息系统。
## 特性
* 简单易用
* 基于泛型
* 支持异步消息
* 线程安全
* 支持VCL和Firemonkey
## 如何使用
1. 定义消息ID
~~~pascal
  const     
    CM_Demo   = CM_USER + 0; 
~~~

2. 定义消息接收函数  
~~~pascal
    procedure CMDemo(var Message: TVPLMessage<TObject,String>); message CM_Demo;
~~~
3. 实现消息接收函数
~~~pascal
   procedure Txxx.CMDemo(var Message: TVPLMessage<TObject,String>);
   begin
     Showmessage(Message.Param);
   end
~~~
4. 订阅消息
~~~pascal
  MessageService.AutoSubscribe(xxx);   //MessageService是定义在VPL.Messaging中的一个全局变量
~~~   
 xxx： 为订阅消息的对象
 订阅语句一般放在对象的创建函数中，例如：
 ~~~pascal
   constructor Txxx.Create;
   begin
     MessageService.AutoSubscribe(Self);
   end
~~~
5. 发送消息
~~~pascal
     MessageService.SendMessage(Self,CM_Demo,‘Hello,MessageService!’);
~~~
6. 取消订阅
    当一个对象不再使用，如果他订阅了消息，那么需要取消他订阅.
~~~pascal    
    MessageService.Unsubscribe(xxx);
~~~
取消订阅一般放在对象的销毁函数中.
~~~pascal
   destructor Txxx.Destroy;
   begin
     MessageService.Unsubscribe(Self);
   end
~~~
## 消息类型说明
  **MessageService**定义了三种消息参数类型，在参数个数少于等于2个的情况下，不需要额外定义参数类型，如果需要更多参数个数，可以定义一个记录或者类来实现。
  ~~~pascal
  TVPLMessage<S: class> = record
    MsgID: TMessageID;
    Sender: S;
  public
    constructor Create(const ASender: S;const AMsgID: TMessageID);
  end;
~~~
泛型类型S总是对象类型，为消息发送者。
~~~pascal
  TVPLMessage<S: class;P> = record
    MsgID: TMessageID;
    Sender: S;
    Param: P;
  public
    constructor Create(const ASender: S;const AMsgID: TMessageID;const AParam: P);
  end;
~~~
泛型类型S总是对象类型，为消息发送者,泛型类型P可以是任意类型，此消息类型用于一个参数的应用，或者无参数的查询消息(**参数P，用来返回结果**)
~~~pascal
  TVPLMessage<S: class;P1;P2> = record
    MsgID: TMessageID;
    Sender: S;
    Param1: P1;
    Param2: P2;
  public
    constructor Create(const ASender: S;const AMsgID: TMessageID;const AParam1: P1;const AParam2: P2);
  end;
~~~
泛型类型S总是对象类型，为消息发送者,泛型类型P1可以是任意类型，泛型类型P2可以是任意类型，此类型用于需要2个参数的应用，如果用于查询消息(返回参数的消息)，则**只能由P2返回**。
## API说明
~~~pascal
procedure RegisterMessage(const MessageID: TMessageID); overload;
procedure RegisterMessage(const Messages: array of TMessageID); overload;
~~~
注册消息,只有注册过的消息，在调用AutoSubscribe方法订阅时才会有效,但是如果没有注册过任何消息，则调用AutoSubscribe方法订阅消息时，所有消息都有效。
~~~pascal
procedure UnRegisterMessage(const MessageID: TMessageID); overload;
procedure UnRegisterMessage(const Messages: array of TMessageID); overload;
~~~      
取消注册消息。
~~~pascal
procedure AutoSubscribe(const Subscriber: TObject); overload;inline;
~~~
自动订阅消息，Subscriber为订阅消息的对象，Subscriber对象定义的所有消息函数都会被自动订阅(如果MessageService注册过消息，则只有注册过的消息才会被订阅)
~~~pascal      
procedure AutoSubscribe(const Subscriber: TObject;const Sender: TObject); overload;
~~~
含义同上一个函数，不同的是只有发送者为Sender的消息才会分派到消息函数。使用该函数需要注意**在Sender对象不在有效时，需要调用Unsubscribe(Sender)以取消Sender的引用**。
~~~pascal
procedure Subscribe(const MessageID: TMessageID;const Listener: TVPLListener); overload; inline;
procedure Subscribe(const Sender: TObject;const MessageID: TMessageID;const Listener: TVPLListener); overload; inline;
procedure Subscribe(const Subscriber: TObject;const MessageID: TMessageID); overload;
procedure Subscribe(const Subscriber: TObject;const Sender: TObject;const MessageID: TMessageID); overload;
procedure Subscribe(const MessageID: TMessageID;const ListenerMethod: TVPLListenerMethod); overload;
procedure Subscribe(const Sender: TObject;const MessageID: TMessageID;const ListenerMethod: TVPLListenerMethod); overload;
~~~
手动订阅消息函数，MessageID为订阅的消息ID,Listener为消息函数，Sender为指定消息发送者，ListenerMethod为消息方法,Subscriber为订阅对象。     
~~~pascal
      procedure SubscribePriority(const Subscriber: TObject;const MessageID: TMessageID;const Priority: Integer=0);
~~~
设置订阅者优先级，0为最高，优先级高的订阅者，消息会先派送。此函数主要解决订阅同一消息的多个订阅者之间的消息处理顺序问题。
~~~pascal
procedure Unsubscribe(const MessageID: TMessageID); overload;  inline;
procedure Unsubscribe(const Subscriber: TObject); overload; inline;
procedure Unsubscribe(const Listener: TVPLListener); overload; inline;
procedure Unsubscribe(const ListenerMethod: TVPLListenerMethod); overload; inline;
procedure Unsubscribe(const Subscriber: TObject;const MessageID: TMessageID); overload; inline;
~~~
手动取消订阅消息，MessageID为取消订阅的消息ID，Subscriber为取消订阅的订阅者，Listener为取消订阅的函数，ListenerMethod为取消订阅的方法
~~~pascal
procedure SendMessage(const Sender: TObject;const MessageID: TMessageID); overload;
procedure SendMessage(const Sender: TObject;const MessageID: TMessageID;const Params: TObject;const ADispose: Boolean=True); overload;
~~~      
发送消息，Sender为消息发送者,MessageID为消息ID,如果参数为对象类型,ADispose参数用来指示消息发送完成后，对象参数是否释放。

~~~pascal
procedure SendMessage(const Sender: TObject;const MessageID: TMessageID;const Params: array of const); overload;
procedure SendMessage(const Sender: TObject;const MessageID: TMessageID;const Params: TArray<TVarRec>); overload;
~~~      
**MessageService**支持开放数组参数，也支持返回开放数组。这个特性可以使得**MessageService**突破2个参数的限制。不过Delphi的开放数组对于参数有一些限制，比如开放数组不支持记录类型，枚举类型等。开放数组类型系统会自动转换为TArray\<TVarRec\>类型，所以如果返回值为开放数组类型，返回值类型参数类型应该定义为TArray\<TVarRec\>
~~~pascal
procedure SendMessage<P>(const Sender: TObject;const MessageID: TMessageID; const Param: P); overload;
procedure SendMessage<P1,P2>(const Sender: TObject;const MessageID: TMessageID; const Param1: P1;const Param2: P2); overload;
~~~
支持泛型参数的消息发送函数,P,P1,P2为参数类型。可以为任意类型。发送端的参数类型以及个数应该与接收端(消息函数)一致,比如
发送消息
        MessageService.SendMessage<String>(nil,CM_Demo,'Hello MessageService!');
则消息函数定义为
~~~pascal
        procedure CMDemo(var Message: TVPLMessage<TObject,String>); message CM_Demo;       
~~~
如果发送消息   
~~~pascal
        MessageService.SendMessage<String,Integer>(nil,CM_Demo,'Hello MessageService!');
~~~         
则消息函数定义为
~~~pascal
        procedure CMDemo(var Message: TVPLMessage<TObject,String,Integer>); message CM_Demo;       
~~~
~~~pascal
function GetMessage<V>(const Sender: TObject;const MessageID: TMessageID): V; overload; inline;
function GetMessage<P,V>(const Sender: TObject;const MessageID: TMessageID; const Param: P): V; overload; inline;
function GetMessage<V>(const Sender: TObject;const MessageID: TMessageID;const Params: array of const): V; overload;
~~~
发送消息，并获得返回值，如果发送参数为开放数组，则接收函数参数类型应该定义为TAarray\<TVarRec\>，同样的如果返回值时开放数组，那么返回参数类型也应该定义为TAarray\<TVarRec\>，需要注意的是，返回值必须是通过最后一个参数返回的(如果消息参数为2个参数(第一个参数为消息发送者)，则返回值是第二个参数，如果消息参数为3个，则返回值是第3个参数)
~~~pascal
procedure SendMessageWithResult<V>(const Sender: TObject;const MessageID: TMessageID; var Value: V); overload;
procedure SendMessageWithResult<P,V>(const Sender: TObject;const MessageID: TMessageID; const Param: P;var Value: V); overload;
procedure SendMessageWithResult<V>(const Sender: TObject;const MessageID: TMessageID;const Params: array of const;var Value: V); overload;
~~~
发送消息，并获得返回值，如果发送参数为开放数组，则接收函数参数类型应该定义为TAarray\<TVarRec\>，同样的如果返回值时开放数组，那么返回参数类型也应该定义为TAarray\<TVarRec\>，需要注意的是，返回值必须是通过最后一个参数返回的(如果消息参数为2个参数(第一个参数为消息发送者)，则返回值是第二个参数，如果消息参数为3个，则返回值是第3个参数)
~~~pascal
procedure PostMessage(const Sender: TObject;const MessageID: TMessageID;const Synchronize: Boolean=False); overload;
procedure PostMessage(const Sender: TObject;const MessageID: TMessageID;const Message: TObject;const Synchronize: Boolean=False;const ADispose: Boolean=True); overload;
procedure PostMessage(const Sender: TObject;const MessageID: TMessageID;const Params: array of const;const Synchronize: Boolean=False); overload;
~~~
发送异步消息，Synchronize为消息函数执行是否需要同步，True需要同步，False不需要同步,如果参数为对象类型，ADispose来指示是否在消息发送完后释放对象.True释放，False不释放。

## 许可协议

MIT[https://opensource.org/license/mit/]