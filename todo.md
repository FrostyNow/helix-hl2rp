# 이 파일은 메모용이므로 읽지 말 것/내 허락도 없이 바로 작업하지도 마

# 테스트
- 탄약 박스 시퀀스 애니메이션
- 담배
- 앰비언트
- 투척물
- 인식 안 된 ic의 이름이 투명해지지 않음
- SitAnywhere 화살표

# 우선순위 높음
- itemcrate preset 미리보기
- 애드온 정리
- 콤바인 감시인 본머지

# 우선순위 낮음
- 잠글 수 있는 저장되는 차량
- 하늘에 체공하는 플레어
- 자동 디스패치
- 미디어 플레이어 기반 화면 엔티티 추가
- DoorSetOwner 오프라인 캐릭터 고치기
- 스탠드, 전등
- 광원에 반응하는 패널
- 영어 보이스

# 아이디어
- 작전 플러그인: 활성화 시, 캐릭터를 로드, 리스폰한 플레이어에게 화면 전체를 채우는 스크린 출력(스크린은 현재 상황에 대한 안내, 같은 세력 중에서 관리자가 아닌 플레이어를 관전하는 카메라, 없다면 mapscene 출력), 그동안 플레이어는 관리자가 사전에 명령어로 지정한 위치에 텔레포트. 작전을 투입시키면 스크린 출력 중지.
- 인트로와 엔딩 크레딧

[Universal Bullet Penetration] lua/autorun/universal_bullet_penetration.lua:145: Tried to use a NULL entity!
  1. GetClass - [C]:-1
   2. unknown - lua/autorun/universal_bullet_penetration.lua:145
    3. unknown - lua/includes/modules/hook.lua:313
     4. FireBullets - [C]:-1
      5. runCallback - lua/autorun/universal_bullet_penetration.lua:97
       6. unknown - lua/autorun/universal_bullet_penetration.lua:159
        7. FireBullets - [C]:-1
         8. PrimaryAttack - lua/glide/vsweps/combine_apc_turret.lua:62
          9. PrimaryAttackInternal - lua/glide/vsweps/base.lua:147
           10. InternalThink - lua/glide/vsweps/base.lua:189
            11. WeaponThink - lua/entities/base_glide/sv_weapons.lua:159
             12. unknown - lua/entities/base_glide/init.lua:673