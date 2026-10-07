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

@warning_ignore("unused_signal")
signal part_acquired(part_id: StringName)

@warning_ignore("unused_signal")
signal relay_activated(relay_id: StringName)

## 화면 알림 문구 요청
@warning_ignore("unused_signal")
signal toast_requested(text: String)

## 의체 메뉴 열기 요청. editable이면 장착·강화를 바꿀 수 있다. (중계기)
@warning_ignore("unused_signal")
signal body_menu_requested(editable: bool)

## 보스전 시작 (boss는 Boss 노드)
@warning_ignore("unused_signal")
signal boss_started(boss: Node)

@warning_ignore("unused_signal")
signal boss_defeated(boss_id: StringName)
