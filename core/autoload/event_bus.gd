extends Node
## 전역 시그널 허브. 형제 노드나 멀리 떨어진 노드끼리 통신할 때 사용한다.
## 마일스톤이 진행되면서 시그널을 추가한다.

@warning_ignore("unused_signal")
signal player_died

@warning_ignore("unused_signal")
signal player_respawned

@warning_ignore("unused_signal")
signal player_dashed(direction: float)

## 플레이어 공격이 대상에 맞음 (부품 효과 등이 구독한다)
@warning_ignore("unused_signal")
signal hit_landed(target: Node, damage: int)

@warning_ignore("unused_signal")
signal enemy_killed(enemy: Node)

## 화면 흔들림 요청. intensity는 0~1
@warning_ignore("unused_signal")
signal screen_shake_requested(intensity: float)

## 화면 전체 섬광 요청
@warning_ignore("unused_signal")
signal screen_flash_requested(color: Color, duration: float)
