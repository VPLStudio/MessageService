# MessageService
*[中文](README_zh.md)*
## Introduction
**MessageService**It is a message publishing and subscribing system suitable for Delphi,different from other message systems,simple messages do not need to define classes,interface.**MessageService** is based on message ID,with the help of generics to achieve a more free,flexible and convenient message system.
## Features
* Simple and easy to use
* Based on generics
* Asynchronous messages are supported
* Thread safe
* VCL and Firemonkey are supported
## Usage
1. Define the message ID
~~~pascal
  const     
    CM_Demo   = CM_USER + 0; 
~~~

2. Define a message receiving function  
~~~pascal
    procedure CMDemo(var Message: TVPLMessage<TObject,String>); message CM_Demo;
~~~
3. Implement a message receiving function
~~~pascal
   procedure Txxx.CMDemo(var Message: TVPLMessage<TObject,String>);
   begin
     Showmessage(Message.Param);
   end
~~~
4. Subscribe to messages
~~~pascal
  MessageService.AutoSubscribe(xxx);   ///MessageService is a global variable defined in VPL.Messaging
~~~   
 xxx： is the object to which the message is subscribed
 Subscription statements are typically placed in the object's creation function,e.g：
 ~~~pascal
   constructor Txxx.Create;
   begin
     MessageService.AutoSubscribe(Self);
   end
~~~
5. Send a message
~~~pascal
     MessageService.SendMessage(Self,CM_Demo,‘Hello,MessageService!’);
~~~
6. Unsubscribe message
When an object is no longer in use, if he subscribes to the message, then he needs to unsubscribe.
~~~pascal    
    MessageService.Unsubscribe(xxx);
~~~
Unsubscribing is usually placed in the object's destruction function.
~~~pascal
   destructor Txxx.Destroy;
   begin
     MessageService.Unsubscribe(Self);
   end
~~~
## Introduction to message types
  **MessageService** defines three types of message parameters, if the number of parameters is less than or equal to 2, there is no need to define additional parameter types, if you need more parameters, you can define a record or class to implement it.
  ~~~pascal
  TVPLMessage<S: class> = record
    MsgID: TMessageID;
    Sender: S;
  public
    constructor Create(const ASender: S;const AMsgID: TMessageID);
  end;
~~~
The generic type S is always an object type, for the message sender.
~~~pascal
  TVPLMessage<S: class;P> = record
    MsgID: TMessageID;
    Sender: S;
    Param: P;
  public
    constructor Create(const ASender: S;const AMsgID: TMessageID;const AParam: P);
  end;
~~~
The generic type S is always an object type, which is the message sender, and the generic type P can be any type, which is used for the application of a single parameter, or for a parameterless query message (**parameter P, which is used to return a result**)
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
The generic type S is always an object type, for the message sender, the generic type P1 can be any type, the generic type P2 can be any type, this type is used in applications that require 2 parameters, and if it is used to query the message (a message that returns parameters), then it can only be returned by P2.
## API Introduction
~~~pascal
procedure RegisterMessage(const MessageID: TMessageID); overload;
procedure RegisterMessage(const Messages: array of TMessageID); overload;
~~~
Registered messages, only registered messages will be valid when calling the AutoSubscribe method to subscribe, but if no messages have been registered, all messages will be valid when the AutoSubscribe method is called to subscribe to messages.
~~~pascal
procedure UnRegisterMessage(const MessageID: TMessageID); overload;
procedure UnRegisterMessage(const Messages: array of TMessageID); overload;
~~~      
Unregister the message.
~~~pascal
procedure AutoSubscribe(const Subscriber: TObject); overload;inline;
~~~
Automatically subscribe to messages, Subscriber is the object of subscribing to messages, and all message functions defined by the Subscriber object will be automatically subscribed (if the MessageService has registered messages, only the registered messages will be subscribed)
~~~pascal      
procedure AutoSubscribe(const Subscriber: TObject;const Sender: TObject); overload;
~~~
The meaning is the same as the previous function, except that only messages with a sender are dispatched to the message function. When using this function, you need to note that **when the Sender object is not valid, you need to call Unsubscribe(Sender) to unreference the Sender**
~~~pascal
procedure Subscribe(const MessageID: TMessageID;const Listener: TVPLListener); overload; inline;
procedure Subscribe(const Sender: TObject;const MessageID: TMessageID;const Listener: TVPLListener); overload; inline;
procedure Subscribe(const Subscriber: TObject;const MessageID: TMessageID); overload;
procedure Subscribe(const Subscriber: TObject;const Sender: TObject;const MessageID: TMessageID); overload;
procedure Subscribe(const MessageID: TMessageID;const ListenerMethod: TVPLListenerMethod); overload;
procedure Subscribe(const Sender: TObject;const MessageID: TMessageID;const ListenerMethod: TVPLListenerMethod); overload;
~~~
Manually subscribe to a message function, MessageID is the message ID of the subscription, Listener is the message function, Sender is the specified message sender, ListenerMethod is the message method, and Subscriber is the subscription object.      
~~~pascal
      procedure SubscribePriority(const Subscriber: TObject;const MessageID: TMessageID;const Priority: Integer=0);
~~~
Set the subscriber priority, 0 is the highest, and the subscriber with the highest priority will send the message first. This function mainly solves the problem of message processing order between multiple subscribers who subscribe to the same message.
~~~pascal
procedure Unsubscribe(const MessageID: TMessageID); overload;  inline;
procedure Unsubscribe(const Subscriber: TObject); overload; inline;
procedure Unsubscribe(const Listener: TVPLListener); overload; inline;
procedure Unsubscribe(const ListenerMethod: TVPLListenerMethod); overload; inline;
procedure Unsubscribe(const Subscriber: TObject;const MessageID: TMessageID); overload; inline;
~~~
To manually unsubscribe from a message, MessageID is the unsubscribed message ID, Subscriber is the unsubscribed subscriber, Listener is the unsubscribed function, and ListenerMethod is the unsubscribed method.
~~~pascal
procedure SendMessage(const Sender: TObject;const MessageID: TMessageID); overload;
procedure SendMessage(const Sender: TObject;const MessageID: TMessageID;const Params: TObject;const ADispose: Boolean=True); overload;
~~~      
If the parameter is an object type, the ADispose parameter is used to indicate whether the object parameter is released after the message is sent.
~~~pascal
procedure SendMessage(const Sender: TObject;const MessageID: TMessageID;const Params: array of const); overload;
procedure SendMessage(const Sender: TObject;const MessageID: TMessageID;const Params: TArray<TVarRec>); overload;
~~~      
MessageService supports open array parameters and also returns open arrays. This feature allows MessageService to break through the limit of 2 parameters. However, Delphi's open array has some restrictions on parameters, such as open arrays do not support record types, enumeration types, etc. The open array type system will automatically convert to the TArray\<TVarRec\> type, so if the return value is an open array type, the return value type parameter type should be defined as TArray\<TVarRec\>
~~~pascal
procedure SendMessage<P>(const Sender: TObject;const MessageID: TMessageID; const Param: P); overload;
procedure SendMessage<P1,P2>(const Sender: TObject;const MessageID: TMessageID; const Param1: P1;const Param2: P2); overload;
~~~
Message sending functions with generic parameters are supported, with P, P1, and P2 as parameter types. Can be of any type. The type and number of parameters on the sender should be the same as those on the receiver (message function), for example
Send a message
~~~pascal
        MessageService.SendMessage<String>(nil,CM_Demo,'Hello MessageService!');
~~~
then the message function is defined as
~~~pascal
        procedure CMDemo(var Message: TVPLMessage<TObject,String>); message CM_Demo;       
~~~
If you send a message  
~~~pascal
        MessageService.SendMessage<String,Integer>(nil,CM_Demo,'Hello MessageService!');
~~~         
then the message function is defined as
~~~pascal
        procedure CMDemo(var Message: TVPLMessage<TObject,String,Integer>); message CM_Demo;       
~~~
~~~pascal
function GetMessage<V>(const Sender: TObject;const MessageID: TMessageID): V; overload; inline;
function GetMessage<P,V>(const Sender: TObject;const MessageID: TMessageID; const Param: P): V; overload; inline;
function GetMessage<V>(const Sender: TObject;const MessageID: TMessageID;const Params: array of const): V; overload;
~~~
Send a message and get the return value, if the sending parameter is an open array, then the receiving function parameter type should be defined as TAarray\<TVarRec\>, and similarly, if the return value is an open array, then the return parameter type should also be defined as TAarray\<TVarRec\>, it should be noted that the return value must be returned by the last parameter (if the message parameter is 2 parameters (the first parameter is the message sender), the return value is the second parameter, If the message parameter is 3, the return value is the 3rd parameter)
~~~pascal
procedure SendMessageWithResult<V>(const Sender: TObject;const MessageID: TMessageID; var Value: V); overload;
procedure SendMessageWithResult<P,V>(const Sender: TObject;const MessageID: TMessageID; const Param: P;var Value: V); overload;
procedure SendMessageWithResult<V>(const Sender: TObject;const MessageID: TMessageID;const Params: array of const;var Value: V); overload;
~~~
Send a message and get the return value, if the sending parameter is an open array, then the receiving function parameter type should be defined as TAarray\<TVarRec\>, and similarly, if the return value is an open array, then the return parameter type should also be defined as TAarray\<TVarRec\>, it should be noted that the return value must be returned by the last parameter (if the message parameter is 2 parameters (the first parameter is the message sender), the return value is the second parameter, If the message parameter is 3, the return value is the 3rd parameter)
~~~pascal
procedure PostMessage(const Sender: TObject;const MessageID: TMessageID;const Synchronize: Boolean=False); overload;
procedure PostMessage(const Sender: TObject;const MessageID: TMessageID;const Message: TObject;const Synchronize: Boolean=False;const ADispose: Boolean=True); overload;
procedure PostMessage(const Sender: TObject;const MessageID: TMessageID;const Params: array of const;const Synchronize: Boolean=False); overload;
~~~
If the parameter is an object type, ADispose indicates whether the object is released after the message is sent.

## License

MIT[https://opensource.org/license/mit/]