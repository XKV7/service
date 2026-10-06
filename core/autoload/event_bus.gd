extends Node
## 전역 시그널 허브. 형제 노드나 멀리 떨어진 노드끼리 통신할 때 사용한다.
## 마일스톤이 진행되면서 시그널을 추가한다.

@warning_ignore("unused_signal")
signal player_died

@warning_ignore("unused_signal")
signal player_dashed(direction: float)
