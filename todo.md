# 이 파일은 메모용이므로 읽지 말 것/내 허락도 없이 바로 작업하지도 마

# 테스트
- 음악 기능: request 이후 무반응
- 브린캐스트: vcd 재생 안 됨 (여전히)
- 고정식 무전기: 발신이 안되는 문제, 음성을 여러개 칠 때 안되는 문제
- IP 차단 테스트

# 우선순위 높음
- 작업용 모니터에서 기록이 저장이 안되는 문제
- 사망한 상태에서 수갑 채우기 (revive하면 수갑 채워지게)

- 출혈 시각적 효과
- 감시인 용어집
- SitAnywhere 화살표 고치기
- 캐릭터 선택하지 않은 시점에서 간헐적으로 mapscene이 제대로 안보이는 문제
- 담배
- 아이템 청소 로직 점검

# 우선순위 낮음
- 기관총/바리케이트 설치
- 비둘기
- 콤바인 감시인 본머지
- 자동 디스패치
- 미디어 플레이어 기반 화면 엔티티 추가
- 라디오 채널 하나 찾기
- DoorSetOwner 오프라인 캐릭터 고치기
- DoorReset
- act 취할때 바로 행동으로 옮기는게 아니라, 자기 자신 모델링을 한 반투명 엔티티(자신에게만 보임)을 플레이어가 위치시키도록 하고, 결정한 장소에 똑같이 자세를 취하도록 만들기
- 차임벨, 스탠드, 전등
- 광원에 반응하는 패널
- 첫번째 락픽만 내구도 튼튼하고 나머지는 점점 약해지는데, 개별로 적용하도록
- 맵상 버튼 누르면 기능

# 아이디어
- 작전 플러그인: 활성화 시, 캐릭터를 로드, 리스폰한 플레이어에게 화면 전체를 채우는 스크린 출력(스크린은 현재 상황에 대한 안내, 같은 세력 중에서 관리자가 아닌 플레이어를 관전하는 카메라, 없다면 mapscene 출력), 그동안 플레이어는 관리자가 사전에 명령어로 지정한 위치에 텔레포트. 작전을 투입시키면 스크린 출력 중지.
- 자동 음성 대사 플러그인: 활성화 시, b메뉴(bind가능)으로 수동 선택도 가능(상황별로 준비). 이때 목록은 cssource에서 대사 선택하듯이 하고, 마우스 옆 앞뒤키(혹은 방향키)로 다음 페이지 보기.




[Srlion's Hook Library] gamemodes/ixhl2rp/schema/items/bags/sh_suitcase.lua:105: attempt to index a nil value
  1. Equip - gamemodes/ixhl2rp/schema/items/bags/sh_suitcase.lua:105
   2. unknown - gamemodes/helix/gamemode/core/meta/sh_player.lua:504
    3. ProtectedCall - [C]:-1
     4. unknown - lua/includes/extensions/entity.lua:158
      5. unknown - lua/includes/modules/hook.lua:313