 `GODOT` `MIT License`
 
만든사람 : 게임만드는까치

-2025.01.19

치지직용 시청자와 소통하는 게임을 만들기 위해 제작한 치지직 채팅 받는 노드를 만들었습니다.

ChatReceiver노드에 원하는 방송의 ID (상단 주소의 가장 끝 문자열)을 넣어 사용합니다.

HTTP를 통해 채널의 ID에서 채널의 채팅 ID를 받아오고,

웹소켓을 통해 채팅채널 ID를 넣어 채팅 로그를 받아오는 식입니다.(아마도? 비전공자라 정확히 맞는지는 모르겠네요)

ChatReceiver 노드의 ChatReceived(Nickname, Msg) Signal을 사용하여 편하게 사용하실 수 있습니다.

현재 Example 프로젝트는 이걸 바탕으로 간단한 채팅 오버레이? 를 만들어놨습니다.


제작에 참고한 것들 : 

[치지직] 웹 사이트 구조 분석(채팅) - https://twoicefish-secu.tistory.com/630

치지직 API 연구 대략적인 결과 - https://gall.dcinside.com/mgallery/board/view/?id=huz&no=457095
