# CLAUDE.md

이 파일은 Claude Code가 이 프로젝트에서 작업할 때 따르는 규칙이다. 기획 내용은 `GDD.md`를 참고한다.

## 프로젝트 개요
- 게임: **ROOT ACCESS** — Godot 4.x (4.4 이상) 기반 2D 사이드스크롤 사이버펑크 액션, 스테이지형
- 언어: GDScript (C# 사용 안 함)
- 목적: 1~2시간 분량으로 완성하는 것. 동시에 **다음 게임에서 재사용할 수 있는 코어 시스템**을 만드는 것이 핵심 목표다.
- 그래서 "이 게임에서만 돌아가는 코드"보다 "다른 게임에 폴더째 옮겨도 돌아가는 코드"를 우선한다.

## 코드 규칙
- 모든 GDScript는 **정적 타입**을 사용한다. (`var speed: float = 200.0`, `func take_damage(amount: int) -> void:`)
- 재사용할 클래스에는 `class_name`을 붙인다.
- 매직 넘버는 금지한다. 수치는 `@export` 변수나 Resource(.tres)로 뺀다. 기준 수치는 `GDD.md`를 따른다.
- 노드 참조는 `@onready var x: Node = $Path` 또는 `%UniqueName`을 사용한다. 깊은 경로 하드코딩(`get_node("../../A/B")`)은 금지한다.
- 노드 간 통신은 "호출은 아래로, 시그널은 위로" 원칙을 따른다. 형제나 먼 노드끼리는 `EventBus` 오토로드 시그널로 통신한다.
- 입력은 키 코드를 직접 쓰지 않고 반드시 Input Map 액션 이름으로 처리한다.
  - `move_left`, `move_right`, `move_up`, `move_down`, `jump`, `attack`, `fire`(레일건), `dash`, `hack`, `interact`, `menu`, `pause`
- 물리 관련 로직은 `_physics_process`, 시각 효과는 `_process`에서 처리한다.
- 주석과 커밋 메시지는 한국어로 작성한다.

## 아키텍처

### 1. 컴포넌트 (재사용 핵심)
`res://core/components/`에 두고, 씬에 자식 노드로 붙여서 조합한다.
- `HealthComponent`: hp, max_hp, `damaged(amount)`, `healed`, `died` 시그널, 피격 무적 시간
- `HitboxComponent` (Area2D): 공격 판정. AttackData를 보유한다.
- `HurtboxComponent` (Area2D): 피격 판정. Hitbox와 겹치면 HealthComponent에 데미지를 전달하고 `hit_landed` 시그널을 공격자 쪽에 알린다 (연산력 획득용).
- `ResourceGaugeComponent`: 범용 게이지 (최대치, 현재치, 증감, 변경 시그널). 연산력에 사용한다.
- `KnockbackComponent`: 피격 방향으로 밀려나는 처리
- `StunComponent`: 정지·경직 상태 관리 (시스템 정지용). 정지 중 받는 피해 배율 포함

### 2. 상태머신
`res://core/state_machine/`
- `StateMachine` 노드와 `State` 베이스 클래스(`enter()`, `exit()`, `physics_update(delta)`, `handle_input(event)`)로 구성한다.
- 플레이어, 일반 적, 보스 모두 같은 StateMachine을 사용한다.
- 상태 전환은 `transitioned.emit(self, "StateName")` 시그널로 한다.
- 보스 패턴은 상태 하나 = 공격 패턴 하나로 만들고, 패턴 선택은 별도 `BossBrain` 노드가 담당한다 (페이즈별 패턴 목록과 가중치).

### 3. 데이터 주도 설계
`res://data/`에 커스텀 Resource로 정의한다.
- `AttackData`: 데미지, 시작 딜레이, 판정 시간, 넉백, 히트스톱 시간, 흔들림 세기
- `WeaponData`: id, 이름, 설명, 콤보별 AttackData 배열, 사거리, 특수 효과
- `PartData`: id, 이름, 설명, 아이콘, 레벨별 효과(StatModifier 배열 또는 특수 효과 id), 강화 비용
- `EnemyData`: HP, 피해, 이동 속도, 감지 거리, 드랍 데이터 양
- `DialogueData`: 화자, 대사 줄 배열
- 밸런스 조정은 코드가 아니라 .tres 파일 수정으로 할 수 있어야 한다.
- 모든 무기·부품·기억 조각은 고유 문자열 id를 가지며 세이브에는 id로 저장한다.

### 4. 스탯과 부품 (core)
`res://core/stats/`
- `StatSheet`: 기본 수치 + `StatModifier` 목록 → 최종 수치를 계산한다. (예: dash_cooldown, attack_mult, damage_taken_mult, max_hp, energy_per_hit, railgun_charge_time)
- `StatModifier`: 대상 스탯, 연산 방식(덧셈/곱셈), 값, 출처 id
- 부품을 장착하거나 해제하면 해당 출처의 모디파이어만 추가·제거한다.
- 조건부 효과(예: N마리 처치 시 회복, 대시 직후 공격력 증가)는 `PartEffect` 스크립트로 분리하고 EventBus 시그널을 구독해서 동작한다.
- 부품별 효과를 플레이어 코드 안에 if문으로 하드코딩하지 않는다.

### 5. 대사 시스템 (core)
`res://core/dialogue/`
- `DialogueBox`: DialogueData를 받아 한 글자씩 출력, 스킵, 끝나면 `finished` 시그널
- 컷신은 `AnimationPlayer` + 대사 호출로 구성한다. 컷신 중에는 플레이어 입력을 막는다.

### 6. 오토로드
- `EventBus`: 전역 시그널 (player_died, enemy_killed, hit_landed, boss_defeated, part_acquired, memory_acquired, relay_activated 등)
- `GameState` (`game/game_state.gd`, 게임 전용이라 game/에 둔다): 현재 지역, 중계기, 보유·장착 부품과 레벨, 무기, 스킬 해금, 데이터, 의체 잔해, 기억 조각, 열린 숨겨진 공간, 본 컷신, 플레이 시간
- `SaveManager`: GameState를 `user://save.json`으로 저장·로드
- `AudioManager`: SFX/BGM 재생
- `SceneLoader`: 스테이지 전환과 페이드

### 7. 게임필 (Juice)
`res://core/feel/`
- `HitStop`: 타격 시 짧게 `Engine.time_scale`을 조절한다.
- `CameraShake`: Camera2D 흔들림
- 셰이더: 타격 흰색 플래시, 글리치, RGB 분리 (`res://assets/shaders/`)

## 폴더 구조
```
res://
├── core/              # 다음 게임에 그대로 가져갈 코드
│   ├── components/
│   ├── state_machine/
│   ├── stats/
│   ├── dialogue/
│   ├── save/
│   ├── feel/
│   └── autoload/
├── game/              # 이 게임 전용
│   ├── player/
│   │   └── states/
│   ├── weapons/
│   ├── parts/         # PartEffect 스크립트
│   ├── enemies/
│   ├── bosses/
│   │   ├── train/
│   │   ├── miso/
│   │   └── ark/
│   ├── traps/
│   ├── objects/       # 중계기, 의체 잔해, 데이터 캐시, 가짜 벽, 기억 조각
│   ├── levels/
│   │   ├── prologue/
│   │   ├── ch1_subway/
│   │   ├── ch2_market/
│   │   └── ch3_tower/
│   ├── cutscenes/
│   └── ui/
├── data/              # .tres 리소스
│   ├── attacks/
│   ├── weapons/
│   ├── parts/
│   ├── enemies/
│   └── dialogue/
├── assets/
│   ├── sprites/
│   ├── audio/
│   ├── fonts/
│   └── shaders/
└── tests/
```
**규칙**: `core/`는 `game/`을 절대 참조하지 않는다. 의존 방향은 game → core 한 방향만 허용한다.

## 충돌 레이어 (Project Settings에 이름 지정)
1. world (지형)
2. player
3. enemy
4. player_hitbox
5. enemy_hitbox
6. interactable
7. pickup
8. hazard (함정)
9. hologram (홀로 망령 등 근접 공격이 통과하는 대상)

## .tscn 파일 작업 시 주의
- .tscn은 텍스트이므로 직접 수정할 수 있지만, 형식이 깨지면 씬이 열리지 않는다. 수정 후에는 반드시 아래 검증을 실행한다.
- 복잡한 노드 트리는 `.tscn`을 직접 편집하기보다 스크립트의 `_ready()`에서 생성하는 쪽을 고려한다.
- 리소스 경로를 바꿀 때는 참조하는 모든 .tscn과 .tres를 함께 수정한다.

## 검증
작업이 끝나면 다음을 실행해서 에러가 없는지 확인한다.
```
godot --headless --path . --import
godot --headless --path . --quit-after 60
godot --headless --path . res://tests/test_player_movement.tscn
godot --headless --path . res://tests/test_combat.tscn
godot --headless --path . res://tests/test_enemies.tscn
```
- 테스트는 오토로드가 필요하므로 `-s`가 아니라 씬(`tests/*.tscn`)으로 실행한다.
- Input Map은 `tests/tools/setup_input_map.gd`로 다시 생성할 수 있다. (`godot --headless --path . -s res://tests/tools/setup_input_map.gd`)
출력에 `ERROR` 또는 `SCRIPT ERROR`가 있으면 원인을 고치고 다시 실행한다.

## 웹 빌드 (태블릿 크롬에서 플레이용)
```
godot --headless --path . --export-release "Web" build/web/index.html
python3 tests/tools/split_web_build.py build/web
```
- 웹 export 템플릿(4.4.1, `web_nothreads_release.zip`)이 필요하다. 스레드 없는 빌드라 별도 헤더 없이 돌아간다.
- 후처리 스크립트가 wasm을 15MB 이하 조각으로 나누고, `.pck`를 `.wasm` 이름으로 바꾸고, `root-access.html`(문서 골격 없는 페이지)을 만든다.
- 웹에서는 시스템 폰트가 없으므로 한글은 프로젝트 기본 폰트(`assets/fonts/Galmuri11.ttf`, OFL)로 표시한다.

## 작업 방식
- 한 번에 하나의 마일스톤만 진행한다. (`GDD.md`의 마일스톤 순서를 따른다)
- 기능을 추가할 때는 먼저 어떤 파일을 만들고 수정할지 짧게 계획을 말한 뒤 진행한다.
- 아트가 없는 단계에서는 `ColorRect`나 `Polygon2D` 플레이스홀더를 사용한다. 아트 때문에 작업을 멈추지 않는다.
- 기획에 없는 수치나 내용이 필요하면 임의로 정하고, 정한 내용을 작업 보고에 적는다.
- 마일스톤이 끝나면 이 파일 하단의 "진행 상황"을 갱신한다.

## 진행 상황
- [x] M1 이동 — 상태머신 core, Idle/Run/Jump/Fall/Dash, FollowCamera, 테스트 맵(`game/levels/test/`), 이동 테스트
- [x] M2 전투 — 전투 컴포넌트 core, 블레이드 3타·아래 찍기·레일건·시스템 정지, 히트스톱·흔들림·섬광·피격 플래시, 샌드백, 전투 테스트 (플레이어 Hurt/Dead는 M3에서)
- [x] M3 적·함정 — Enemy 베이스와 공통 상태, 적 6종, 함정 3종, 데이터 드랍(GameState), 플레이어 피격·사망·재접속, 안전 지점, 적·함정 테스트
- [ ] M4 성장
- [ ] M5 보스
- [ ] M6 스테이지
- [ ] M7 스토리
- [ ] M8 시스템·UI
- [ ] M9 폴리싱
