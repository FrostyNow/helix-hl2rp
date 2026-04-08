local loreStyles = [[
<style>
    body {
        background-color: #0c0d10;
        color: #e0e0e0;
        font-family: 'NanumBarunGothic', 'NanumGothic', 'Malgun Gothic', 'Inter', 'Segoe UI', sans-serif;
        line-height: 1.8;
        padding: 50px 80px;
        margin: 0;
        -webkit-font-smoothing: antialiased;
        overflow-y: auto;
    }
    ::-webkit-scrollbar { width: 6px; }
    ::-webkit-scrollbar-track { background: transparent; }
    ::-webkit-scrollbar-thumb { background: rgba(255, 255, 255, 0.1); border-radius: 3px; }
    ::-webkit-scrollbar-thumb:hover { background: rgba(255, 255, 255, 0.2); }

    .content {
        animation: fadeIn 0.6s cubic-bezier(0.22, 1, 0.36, 1);
    }
    @keyframes fadeIn {
        from { opacity: 0; transform: translateY(20px); }
        to { opacity: 1; transform: translateY(0); }
    }
    h1 {
        color: #fff;
        font-size: 36px;
        font-weight: 700;
        margin-top: 0;
        margin-bottom: 40px;
        letter-spacing: -1px;
        border-left: 4px solid #bf394b;
        padding-left: 20px;
    }
    .divider {
        height: 1px;
        background: linear-gradient(90deg, rgba(255, 255, 255, 0.1), transparent);
        margin: 50px 0;
    }
    .paragraph {
        margin-bottom: 30px;
        color: #d1d1d1;
        font-size: 17px;
        text-align: justify;
        word-break: keep-all;
        text-indent: 1.5em;
    }
    h2 {
        color: #fff;
        font-size: 22px;
        font-weight: 600;
        margin-top: 20px;
        margin-bottom: 30px;
        text-transform: uppercase;
        letter-spacing: 2px;
        border-bottom: 1px solid rgba(255, 255, 255, 0.1);
        padding-bottom: 15px;
        display: inline-block;
    }
    .term-list {
        display: grid;
        grid-template-columns: 1fr;
        gap: 15px;
    }
    .term-item {
        padding: 24px;
        background: rgba(255, 255, 255, 0.02);
        border: 1px solid rgba(255, 255, 255, 0.04);
        border-radius: 8px;
        transition: all 0.3s ease;
    }
    .term-item:hover {
        background: rgba(255, 255, 255, 0.04);
        border-color: rgba(255, 255, 255, 0.1);
        transform: translateX(5px);
    }
    .term-name {
        color: #fff;
        font-weight: 700;
        font-size: 18px;
        display: block;
        margin-bottom: 12px;
    }
    .term-content {
        color: #b0b0b0;
        font-size: 15px;
        line-height: 1.6;
    }
    .breen { color: #815ab0; font-weight: 600; }
    .overwatch { color: #87313a; font-weight: 600; }
    .ota { color: #ff9d5c; font-weight: 600; }
    .cp { color: #3e5582; font-weight: 600; }
    .cwu { color: #e6e385; font-weight: 600; }
    .conscript { color: #52665b; font-weight: 600; }
    .vort { color: #72dbd6; font-weight: 600; }
    .rebel { color: #ff9d52; font-weight: 600; }
    .lambda { color: #ff9d52; font-weight: 800; }
</style>
]]

PLUGIN.loreTranslations = {
    korean = [[
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
]] .. loreStyles .. [[
</head>
<body>
    <div class="content">
        <h1>우주 공동체의 통치 아래에서</h1>
        
        <div class="paragraph">인류의 평범한 일상이 종말을 고한 것은 20세기 말, 예고 없이 찾아온 두 번의 거대한 침입 때문이었습니다. 먼저 하늘이 찢기며 전 지구를 덮친 포털 폭풍은 우리가 알던 물리적 경계를 무너뜨렸고, 차원의 균열을 통해 쏟아져 들어온 외계 생물들은 도시를 순식간에 사냥터로 바꾸어 놓았습니다. 각국 정부는 급박하게 소개령을 내리고 군을 동원해 저항하려 했으나, 뒤이어 나타난 다차원 제국 콤바인의 압도적인 무력 앞에 인류는 무력했습니다. 단 7시간 만에 전 세계의 방어 체계는 궤멸되었으며, 이 모든 사건의 시발점인 블랙 메사 연구소의 행정관이었던 <span class="breen">월리스 브린</span>은 인류의 멸종을 막는다는 명분 아래 대부를 자처하며 콤바인에게 항복을 선언했습니다. 이로써 지구는 <span class="cp">우주 공동체(Universal Union)</span>라 불리는 초거대 우주 제국의 식민지로 강제 편입되었습니다.</div>
        
        <div class="paragraph">과거의 국가와 민족이라는 개념은 이제 역사 속으로 사라졌습니다. <span class="overwatch">감시인 정부</span>는 인류를 효율적으로 통제하기 위해 기존의 도시들을 해체하고 번호가 매겨진 N번 지구 시스템으로 재편했습니다. 그중에서도 옛 동유럽에 위치한 <span class="cp">17번 지구</span>는 <span class="breen">브린</span>의 수도 행정부가 위치한 중심지로, 도시 한복판에는 하늘을 찌를 듯 솟아오른 거대 금속 탑 <span class="cp">시타델</span>이 지배의 상징처럼 군림하고 있습니다.</div>
        
        <div class="paragraph"><span class="cp">콤바인</span>의 수탈은 인간에게만 국한되지 않습니다. 지구의 자원은 <span class="cp">우주 공동체</span>의 필요에 따라 무자비하게 뽑혀 나가고 있으며, 그 여파로 바다는 급격히 메말라 서서히 밑바닥을 드러냈습니다. 게다가 <span class="cp">콤바인</span>의 방치 속에, 외계에서 유입된 기괴한 동식물들이 파괴된 환경을 잠식하며 지구의 생태계는 회복 불가능한 지점에 이르렀습니다.</div>
        
        <div class="paragraph">이 지옥 같은 환경에서 살아남기 위해 시민들은 생존을 담보로 한 부역의 길을 택하곤 합니다. <span class="cwu">시민 노동 조합</span>에 가입하면 일반적인 강제 노역보다 상대적으로 수월한 노동 감독이나 상점 운영 같은 서비스업에 종사할 수 있는 기회를 얻습니다. 더 나아가 동족을 감시하고 탄압하는 <span class="cp">시민 보호 기동대</span>에 지원하는 이들도 존재합니다. 이들이 인간의 존엄성을 버리고 부역자가 되는 이유는 명확합니다. 비참한 수준의 기본 배급식보다 조금이라도 더 먹을만한 밥을 얻고, 아주 미미하게나마 나은 주거 환경을 보장받기 위해서입니다. 협조자들에게는 <span class="overwatch">감시인 정부</span>가 발행하는 유일한 화폐인 토큰이 지급되는데, 이 토큰이야말로 <span class="cp">17번 지구</span>에서 생존을 이어갈 수 있는 유일한 생명줄이자 힘의 도구로 작용합니다.</div>
        
        <div class="paragraph">거리의 질서를 유지하는 방독면 쓴 <span class="cp">기동대</span> 너머에는, <span class="cp">우주 공동체</span>의 “자랑스러운” 신인류가 될 <span class="ota">감시 부대</span>의 병사들이 그림자처럼 도사리고 있습니다. 그러나 이들은 더 이상 인간이라 부를 수 없는 <span class="cp">우주 공동체</span>의 완벽한 부품들입니다.</div>
        
        <div class="paragraph">무엇보다 잔인한 사실은 <span class="cp">콤바인</span>이 가동한 억제장으로 인해 지구상에서 더 이상 아이가 태어나지 않는다는 점입니다. <span class="breen">월리스 브린</span> 행정관은 연일 선전을 통해 이것이 인류를 번식이라는 원시적인 요람에서 해방시켜 진정한 영생으로 인도하는 진화의 과정이라 선전하지만, 이는 명백한 기만입니다. 실상은 인류를 철저히 소모품으로 부리다 조용히 멸종시키려는 우주적 수탈의 일환일 뿐입니다. 인류는 이제 <span class="cp">시타델</span>의 거대한 그림자 아래서, 다시는 오지 않을 내일을 기다리며 서서히 소멸해가는 마지막 세대로 남겨졌습니다.</div>

        <div class="divider"></div>

        <h2>알아두면 좋은 내용</h2>
        
        <div class="term-list">
            <div class="term-item">
                <span class="term-name"><span class="overwatch">감시인 정부</span></span>
                <div class="term-content"><span class="breen">행정관 월리스 브린</span>을 정부 수반으로 내세우고 있으나, 그 실체는 베일에 싸인 <span class="cp">콤바인 조언자들</span>의 의중에 따라 움직이는 괴뢰 조직입니다. 모든 행정은 <span class="overwatch">감시인 AI</span>의 철저한 계산 아래 집행되며, 극소수의 인간 고급 관료들이 실무를 담당하며 인류를 <span class="cp">우주 공동체</span>의 체제 아래 묶어둡니다.</div>
            </div>
            
            <div class="term-item">
                <span class="term-name"><span class="cp">시민 보호 기동대</span></span>
                <div class="term-content">도시 내부의 치안 유지와 시민 탄압을 전담하는 조직입니다. 더 나은 배급과 거주 환경, 그리고 토큰을 얻기 위해 동족을 배신하고 가담한, 얼굴을 가린 부역자들로 구성됩니다. 거리 곳곳에 상주하며 시민들의 일거수일투족을 감시하고, 즉각적인 폭력을 행사하며 체제의 최전방에서 공포를 유지합니다.</div>
            </div>

            <div class="term-item">
                <span class="term-name"><span class="conscript">민방위</span></span>
                <div class="term-content">시민들 가운데 단순 부역을 목적으로 가담한 인력들입니다. 주로 시설 경비나 저강도 외계종 퇴치, 거리 치안 유지 등 보조적인 임무를 수행하며, 부역자 체계 내에서 가장 낮은 권한과 보상을 받습니다.</div>
            </div>

            <div class="term-item">
                <span class="term-name"><span class="cwu">시민 노동 조합</span></span>
                <div class="term-content">시민 중 일부는 과거에 영위했던 인간다운 삶을 조금이나마 누려 보기 위해 <span class="cwu">시민 노동 조합</span>에 가입합니다. 일반 시민들보다 나은 업무 환경에서 노동 현장을 감독하거나 지정된 상업 행위를 허가받습니다.</div>
            </div>

            <div class="term-item">
                <span class="term-name"><span class="ota">감시인 신인류 부대</span></span>
                <div class="term-content">방독면과 전투복을 벗은 모습을 본 사람이 아무도 없는 미지의 군대입니다. 대규모 소요 사태나 군사적 투입이 필요한 상황이 닥치면 그림자처럼 나타나 압도적인 무력으로 상황을 정리합니다.</div>
            </div>

            <div class="term-item">
                <span class="term-name"><span class="ota">신스</span></span>
                <div class="term-content">우주 공동체가 정복한 외계의 생명체들을 생체 개조하여 병기화한 존재들입니다. <span class="ota">7시간 전쟁</span> 당시 인류의 군대를 처참하게 무너뜨렸던 공포의 상징입니다.</div>
            </div>

            <div class="term-item">
                <span class="term-name"><span class="cp">억제장</span></span>
                <div class="term-content">인류의 번식 능력을 완전히 차단하여 더 이상 아이가 태어나지 않게 만드는 특정 파동입니다. 인류를 마지막 세대로 만들어 서서히 소멸시키려는 우주적 수탈의 수단입니다.</div>
            </div>

            <div class="term-item">
                <span class="term-name"><span class="ota">노바 프로스펙트</span></span>
                <div class="term-content">도시 외곽에 위치한 고도의 보안 수용소입니다. 한 번 이곳으로 끌려간 이들은 결코 돌아오지 못하며, 시민들에게는 '죽음'보다 더한 공포의 대상입니다.</div>
            </div>

            <div class="term-item">
                <span class="term-name"><span class="cp">도시 스캐너와 카메라</span></span>
                <div class="term-content">공중을 부유하는 스캐너와 고정식 감시 카메라가 도처에서 시민들을 감시합니다. <span class="cp">17번 지구</span> 어디에서도 감시인의 눈을 벗어날 수 없습니다.</div>
            </div>

            <div class="term-item">
                <span class="term-name"><span class="cp">반사회와 반시민</span></span>
                <div class="term-content"><span class="overwatch">감시인 정부</span>의 법령을 어긴 자들에게 찍히는 낙인입니다. 반시민으로 분류되는 순간 모든 생존 권한이 박탈되며 즉각적인 물리적 말살의 대상이 됩니다.</div>
            </div>

            <div class="term-item">
                <span class="term-name"><span class="cwu">배급 터미널</span></span>
                <div class="term-content">시민들이 생존을 위한 정체 모를 배급식을 받는 기계입니다. 충성도에 따라 배급의 질이 달라지는, 인류의 굴욕적인 생존 현장입니다.</div>
            </div>

            <div class="term-item">
                <span class="term-name"><span class="vort">노예 보르티곤트</span></span>
                <div class="term-content">구속구에 묶여 도시의 단순 노역에 동원되는 외계 종족입니다. 인류와 함께 <span class="cp">콤바인</span>의 노예로 전락하여 무력하게 하루하루를 보냅니다.</div>
            </div>

            <div class="term-item">
                <span class="term-name"><span class="rebel">저항군</span></span>
                <div class="term-content"><span class="overwatch">감시인</span>의 눈을 피해 인류의 자유를 되찾으려고 분투하는 이들이 있습니다. 특정한 지휘 체계나 질서는 없지만 해방이라는 같은 목표를 위해 움직이는 이들은, 감시를 피해 인적 드문 버려진 옛 시설이나 도시 바깥에 주로 머무릅니다. <span class="overwatch">감시 부대</span>의 소탕 작전이 계속되는 와중에도 <span class="rebel">람다</span> 문양을 상칭으로 하는 <span class="rebel">저항군</span>의 중추는 각 지역에 지하철도라는 비밀 연락망을 갖추고 투쟁하고 있습니다. 소문에 따르면 이들은 블랙 메사 사건에서 외계종의 침략을 저지하는 위대한 업적을 세우고 홀연히 사라진 <span class="rebel">고든 프리맨</span>이라는 남자를 구세주로 기다리고 있습니다.</div>
            </div>

            <div class="term-item">
                <span class="term-name"><span class="cwu">시민 거주지</span></span>
                <div class="term-content">모든 시민이 의무적으로 숙식하는 열악한 공동 거주지입니다. 잠금 장치가 금지되어 있으며 수시로 <span class="cp">기동대</span>의 불심 검문이 이루어집니다.</div>
            </div>
        </div>
    </div>
</body>
</html>
]],
    english = [[
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
]] .. loreStyles .. [[
</head>
<body>
    <div class="content">
        <h1>Under the rule of the Universal Union</h1>
        
        <div class="paragraph">The end of humanity's ordinary life occurred at the close of the 20th century, due to two massive or unannounced invasions. First, the Portal Storms tore through the sky, collapsing the physical boundaries we knew, and alien creatures pouring through the dimensional rifts turned cities into hunting grounds. Governments urgently issued evacuation orders and mobilized militaries, but humanity was powerless against the overwhelming force of the multidimensional empire known as <span class="cp">the Combine</span>. In just seven hours, the world's defense systems were annihilated. <span class="breen">Wallace Breen</span>, administrator of the Black Mesa Research Facility where it all began, brokered a surrender in the name of preventing human extinction. Thus, Earth was forcibly annexed as a colony of <span class="cp">the Universal Union</span>.</div>
        
        <div class="paragraph">Concepts of nations and ethnicities have faded into history. The <span class="overwatch">Overwatch Government</span> disbanded existing cities and reorganized them into numbered "City" systems to efficiently control humanity. <span class="cp">City 17</span>, located in the former Eastern Europe, serves as the capital where <span class="breen">Breen</span>'s administration is situated. At its heart looms <span class="cp">the Citadel</span>, a colossal metallic spire that reigns as a symbol of absolute dominance.</div>
        
        <div class="paragraph"><span class="cp">Combine</span> exploitation is not limited to humans. Earth's resources are ruthlessly extracted for <span class="cp">the Union</span>'s needs, causing seas to dry up and the environment to collapse. Strange alien flora and fauna have occupied the devastated landscapes, pushing Earth's ecosystem beyond the point of recovery.</div>
        
        <div class="paragraph">To survive in this hellish environment, citizens often choose the path of collaboration. Joining the <span class="cwu">Civil Workers Union</span> provides opportunities for lighter labor or service roles like supervising work shifts or operating licensed shops. Some even apply for the <span class="cp">Civil Protection</span> forces to monitor and oppress their own kind. People abandon their dignity for one simple reason: to receive slightly better rations and a marginally improved living environment compared to the miserable baseline. Collaborators are paid in Tokens, the only currency issued by the <span class="overwatch">Overwatch Government</span>, which serves as the sole lifeline and tool of power in <span class="cp">City 17</span>.</div>
        
        <div class="paragraph">Beyond the gas-masked officers maintaining order in the streets lurk the soldiers of the <span class="ota">Overwatch Transhuman Arm</span>—the "proud" new humanity of <span class="cp">the Universal Union</span>. However, they are no longer human, but perfect components of the cosmic machine.</div>
        
        <div class="paragraph">The cruelest fact is the Suppression Field. No more children are born on Earth. Administrator <span class="breen">Breen</span> propagates this as an evolutionary process, freeing humanity from the primitive cradle of reproduction, but this is a deception. In reality, it is a method to use humanity as disposable labor until they quietly fade into extinction. Under the shadow of <span class="cp">the Citadel</span>, humanity remains as the final generation, slowly diminishing while waiting for a tomorrow that will never come.</div>

        <div class="divider"></div>

        <h2>Good to know</h2>
        
        <div class="term-list">
            <div class="term-item">
                <span class="term-name"><span class="overwatch">Overwatch Government</span></span>
                <div class="term-content">Led by <span class="breen">Wallace Breen</span>, but actually a puppet organization controlled by the enigmatic Combine Advisors. Every administrative act is calculated by an <span class="overwatch">Overwatch AI</span>, with elite human bureaucrats executing orders to keep humanity bound.</div>
            </div>
            
            <div class="term-item">
                <span class="term-name"><span class="cp">Civil Protection</span></span>
                <div class="term-content">Officers responsible for internal security and citizen oppression. Masked collaborators who betrayed their own kind for better rations, improved housing, and tokens. They maintain order through immediate violence and surveillance.</div>
            </div>

            <div class="term-item">
                <span class="term-name">Civil Defense</span>
                <div class="term-content">Lower-tier collaborators used for facility security or low-intensity xenian clearing. They represent the lowest authority and compensation in the collaborator hierarchy.</div>
            </div>

            <div class="term-item">
                <span class="term-name"><span class="cwu">Civil Workers Union (CWU)</span></span>
                <div class="term-content">Citizens seeking a semblance of normal life. They supervise labor sites or operate licensed commerce, enjoying slightly better conditions than standard citizens.</div>
            </div>

            <div class="term-item">
                <span class="term-name"><span class="overwatch">Overwatch</span> <span class="ota">Transhuman Arm</span> (<span class="ota">OTA</span>)</span>
                <div class="term-content">A mysterious army whose faces are never seen. They appear only during large-scale unrest or critical combat situations to suppress threats with overwhelming force.</div>
            </div>

            <div class="term-item">
                <span class="term-name">Synths</span>
                <div class="term-content">Bio-engineered war machines created from conquered alien species. They crushed human resistance during the <span class="ota">7 Hour War</span> and remain symbols of absolute power.</div>
            </div>

            <div class="term-item">
                <span class="term-name">Suppression Field</span>
                <div class="term-content">A global field that inhibits human reproduction. It ensures no more children are born, serving as a tool to gradually eliminate the human race after extracting its utility.</div>
            </div>

            <div class="term-item">
                <span class="term-name">Nova Prospekt</span>
                <div class="term-content">A high-security facility outside the city. Those who are sent there for anti-citizen activity never return, becoming subjects of dark rumors and fear.</div>
            </div>

            <div class="term-item">
                <span class="term-name">City Scanners & Cameras</span>
                <div class="term-content">Ubiquitous surveillance units that identity citizens and track suspicious behavior. Nowhere in <span class="cp">City 17</span> is out of reach of the Overwatch's gaze.</div>
            </div>

            <div class="term-item">
                <span class="term-name">Sociocide and Anti-Citizen</span>
                <div class="term-content">Those who violate <span class="overwatch">Overwatch</span> laws. Labeled as outcasts, they lose all rights and are subject to immediate neutralization or transfer to Nova Prospekt.</div>
            </div>

            <div class="term-item">
                <span class="term-name">Rations Terminal</span>
                <div class="term-content">Machines providing synthetic food based on citizen loyalty. It is the site of both humiliation and desperate survival for the citizens.</div>
            </div>

            <div class="term-item">
                <span class="term-name">Enslaved <span class="vort">Vortigaunts</span></span>
                <div class="term-content">An alien race captured by <span class="cp">the Combine</span>, forced into manual labor with green glowing collars. They endure a miserable existence alongside humanity.</div>
            </div>

            <div class="term-item">
                <span class="term-name"><span class="rebel">Resistance</span></span>
                <div class="term-content">There are those who strive to reclaim human freedom, evading the watchful eyes of the <span class="overwatch">Overwatch</span>. Lacking a formal command structure, they are united by a common goal: liberation. They often take refuge in abandoned facilities or outskirts where surveillance is weak. Despite constant suppression by the <span class="overwatch">Overwatch</span>, the backbone of the <span class="rebel">resistance</span>, symbolized by the <span class="rebel">Lambda</span> mark, remains resilient, coordinated via a clandestine network known as the 'Underground Railroad.' Rumors circulate that they await the return of <span class="rebel">Gordon Freeman</span>—the legendary hero of the Black Mesa Incident—as their savior.</div>
            </div>

            <div class="term-item">
                <span class="term-name">Citizen Housing</span>
                <div class="term-content">Mandatory communal housing with poor conditions. Locking doors is forbidden, and unannounced raids by <span class="cp">Civil Protection</span> are frequent.</div>
            </div>
        </div>
    </div>
</body>
</html>
]]
}
