local gc=love.graphics
local max,int,abs,rnd=math.max,math.floor,math.abs,math.random
local byte,find,sub,gsub=string.byte,string.find,string.sub,string.gsub
local ins,rem=table.insert,table.remove
local toN,toS=tonumber,tostring

local par_time={12,11,9,9,8}
local row={"row1","row2","row3","row4","row5"}
local cur={"cur1","cur2","cur3","cur4","cur5"}
local cup={"cup1","cup2","cup3","cup4","cup5"}
local color={
	red={1,0,0},
	green={0,1,0},
	blue={0,0,1},
	yellow={.9,.9,0},
	white={1,1,1},
	grey={.4,.4,.4},
}
local modes={
	"Standard",
	"Easy",
	"Hard",
	"Extreme",
	"Lunatic",
}
local trophy_text={
	"Good.\nNot noob now.",
	"Great.\nLet's go deeper.",
	"Nice?\nMay very hard.",
	"Awesome!\nYou are master now.",
	"Incredible!!!\nGrand Master.",
}
local modeColor={
	color.green,
	color.white,
	color.red,
	color.yellow,
	color.blue,
}
--Lists

gc.setDefaultFilter("nearest")
local img={
	"cup1","cup2","cup3","cup4","cup5",
	--Pixel img
	"music","sound","vibrate",
	"off",
	--Normal img
}
for i=1,#img do
	if i==6 then gc.setDefaultFilter("linear")end
	img[img[i]],img[i]=gc.newImage("image/"..img[i]..".png")
end--Filter

local bgm={
	"title",
	"main",
	"main2",
	"trophy",
}
local sfx={
	"1","2","3","4","5","6","7","8","9","0",
	"del_1","del_2","del_3","del_4",
	"error","check","click","sweep",
	"win","lose","hint"
}
for i=1,#bgm do
	bgm[bgm[i]]=love.audio.newSource("/audio/"..bgm[i]..".ogg","stream")
	bgm[bgm[i]]:setLooping(true)
	bgm[i]=nil
end
for i=1,#sfx do
	sfx[sfx[i]]=love.audio.newSource("/audio/"..sfx[i]..".mp3","static")
	sfx[i]=nil
end

local setting={
	bgm=true,
	sfx=true,
	vib=true,
}
local stat={
	row1=0,row2=0,row3=0,row4=0,row5=0,
	cur1=0,cur2=0,cur3=0,cur4=0,cur5=0,
	cup1=false,cup2=false,cup3=false,cup4=false,cup5=false,
	playing=0,
}

local userdata=love.filesystem.newFile("userdata")
local function splitS(s,sep)
	sep=sep or"/"
	local t={}
	repeat
		local i=find(s,sep)or #s+1
		ins(t,sub(s,1,i-1))
		s=sub(s,i+#sep)
	until #s==0
	return t
end
local function savedata()
	local t={
		"sfx="..toS(setting.sfx),
		"bgm="..toS(setting.bgm),
		"vib="..toS(setting.vib),
		"playing="..toS(stat.playing),
	}
	for i=1,5 do
		ins(t,row[i].."=",toS(stat[row[i]]))
		ins(t,cur[i].."=",toS(stat[cur[i]]))
		ins(t,cup[i].."=",toS(stat[cup[i]]))
	end
	t=table.concat(t,"\r\n")
	--t=love.math.compress(t,"zlib"):getString()
	userdata:open("w")
	userdata:write(t)
	userdata:close()
end
if love.filesystem.getInfo("userdata")then
	userdata:open("r")
	local t=splitS(userdata:read(),"\r\n")
	userdata:close()
	for i=1,#t do
		i=t[i]
		if find(i,"=")then
			local k=sub(i,1,find(i,"=")-1)
			local v=sub(i,find(i,"=")+1)
			if k=="sfx"or k=="bgm"or k=="vib"then
				setting[k]=v=="true"
			elseif k=="playing"then
				v=toN(v)
				stat[k]=v and v>0 and int(v)==v and v or 0
			else
				local pre=k:sub(1,3)
				if pre=="cup"then
					stat[k]=v=="true"
				elseif pre=="row"or pre=="cur"then
					v=toN(v)
					stat[k]=v and v>0 and int(v)==v and v or 0
				end
			end
		end
	end
	if stat.playing>0 then
		stat[cur[stat.playing]]=0
		savedata()
	end
end

local bgmPlaying=nil
local function SFX(s)
	if setting.sfx then
		sfx[s]:stop()
		sfx[s]:play()
	end
end
local function BGM(s)
	if setting.bgm and bgmPlaying~=s then
		if bgmPlaying then bgm[bgmPlaying]:stop()end
		if s then bgm[s]:play()end
		bgmPlaying=s
	end
end
local function VIB(t)
	if setting.vib then
		love.system.vibrate(t)
	end
end

local system
do
	local l={
		Windows=1,
		Android=2,
	}
	system=l[love.system.getOS()]
	l=nil
end--Get operating system

local touching=nil
local function convert(x,y)
	return (x-screenM)*screenK,y*screenK
end

local Fonts={}
local currentFont
local function setFont(s)
	if s~=currentFont then
		if Fonts[s]then
			gc.setFont(Fonts[s])
		else
			local t=love.graphics.setNewFont(s)
			Fonts[s]=t
			gc.setFont(t)
		end
		currentFont=s
	end
end
local function mStr(s,x,y)gc.printf(s,x-400,y,800,"center")end

local game
local input,time
local remain
local info,L
local mes
local tagMenu
local tagList

Button_backmenu={
	{"Yes",360,600,400,80,function()
		if backInfo[2]=="quit"then
			love.event.quit()
		else
			if backInfo[1]==play and game==0 and time>0 then
				stat[cur[mode]]=0
			end
			backInfo[2]()
		end
	end,rgb=color.green},
	{"No",360,700,400,80,function()
		backInfo[1]()
	end,rgb=color.red},
}
Button_menu={
	{"Standard mode",360,400,400,80,function()mode=1;play(true)SFX("check")end,rgb=color.green},
	{"Easy mode",360,500,400,80,function()mode=2;play(true)SFX("check")end},
	{"Hard mode",360,600,400,80,function()mode=3;play(true)SFX("check")end,rgb=color.red},
	{"Extreme mode",360,700,400,80,function()mode=4;play(true)SFX("check")end,rgb=color.yellow},
	{"Lunatic mode",360,800,400,80,function()mode=5;play(true)SFX("check")end,rgb=color.blue},
	{"Quit",360,980,300,100,function()love.keypressed("escape")SFX("error")end,font=55},
	--Play/Quit
	{"",110,400,80,80,function()trophy(1)end,hide=function()return not stat[cup[1]]end,noframe=true,rgb=color.green},
	{"",110,500,82,82,function()trophy(2)end,hide=function()return not stat[cup[2]]end,noframe=true,rgb=color.white},
	{"",110,600,84,84,function()trophy(3)end,hide=function()return not stat[cup[3]]end,noframe=true,rgb=color.red},
	{"",110,700,86,86,function()trophy(4)end,hide=function()return not stat[cup[4]]end,noframe=true,rgb=color.yellow},
	{"",110,800,88,88,function()trophy(5)end,hide=function()return not stat[cup[5]]end,noframe=true,rgb=color.blue},
	--Trophies
	{"",480,60,64,64,function()
		if setting.bgm then BGM()end
		setting.bgm=not setting.bgm
		if setting.bgm then BGM("title")end
		savedata()
	end,noframe=true},
	{"",570,60,64,64,function()
		setting.sfx=not setting.sfx
		if setting.sfx then SFX("error")end
		savedata()
	end,noframe=true},
	{"",660,60,64,64,function()
		setting.vib=not setting.vib
		VIB(.1)
		savedata()
	end,noframe=true},
	--Switches
}
Button_play_1={
	{"1",200,800,135,100,function()charin("1")end,font=90},
	{"2",360,800,135,100,function()charin("2")end,font=90},
	{"3",520,800,135,100,function()charin("3")end,font=90},
	{"4",200,930,135,100,function()charin("4")end,font=90},
	{"5",360,930,135,100,function()charin("5")end,font=90},
	{"6",520,930,135,100,function()charin("6")end,font=90},
	{"7",200,1060,135,100,function()charin("7")end,font=90},
	{"8",360,1060,135,100,function()charin("8")end,font=90},
	{"9",520,1060,135,100,function()charin("9")SFX("click")end,font=90},
	{"check",200,1190,135,100,function()guess()end,rgb=color.green},
	{"0",360,1190,135,100,function()charin("0")end,font=90},
	{"<",520,1190,135,100,function()backspace()SFX("click")end,font=70,rgb=color.red},
	{"X",675,45,40,40,function()love.keypressed("escape")SFX("error")end,noframe=true},
	{"F",660,595,70,70,function()SFX("click")tagMenu=true;Button=Button_play_2 end,font=60,rgb=color.yellow},
}
Button_play_2={
	{"S",60,595,70,70,function()
		SFX("click")
		tagList_s=tagList_s or{{},{},{},{}}
		for i=1,4 do
			for j=1,10 do
				tagList_s[i][j]=tagList[i][j]
			end
		end
	end,font=60,rgb=color.red},
	{"L",150,595,70,70,function()
		SFX("click")
		for i=1,4 do
			for j=1,10 do
				tagList[i][j]=tagList_s[i][j]
			end
		end
	end,font=60,rgb=color.green,hide=function()return not tagList_s end},
	{"X",675,45,40,40,function()love.keypressed("escape")SFX("error")end,noframe=true},
	{"R",570,595,70,70,function()
		SFX("error")
		for i=1,4 do
			for j=1,10 do
				tagList[i][j]=true
			end
		end
	end,font=60,rgb=color.blue},
	{"F",660,595,70,70,function()SFX("click")tagMenu=false;Button=Button_play_1 end,font=60,rgb=color.yellow},
}
Button_play_end={
	{"Restart",360,950,360,120,function()
		if game==2 then
			winRow=0
		end
		play(true)
		SFX("check")
	end,rgb=color.red},
	{"X",675,45,40,40,function()love.keypressed("escape")SFX("error")end,noframe=true},
}
Button_play_trophy={
	{"Get Trophy",360,950,420,120,function()winCup()end,rgb=color.yellow},
}
Button_gettrophy={
	{"Back",360,1000,400,100,function()
		play()
		Button=Button_play_end
	end,rgb=color.green,font=60},
}
Button_trophy={
	{"Back",360,1000,400,100,function()
		menu()
	end,rgb=color.green,font=60},
}

Button=nil--Current button list
Button_sel={nil,0}

local function drawButton()
	for i=1,#Button do
		local b=Button[i]
		if not b.hide or b.hide and not b.hide()then
			local s=b.font or 45
			setFont(s)
			gc.setColor(b.rgb or color.white)
			local zoom,down=0,0--size out pixel&move down pixel
			if Button_sel[1]==b then
				if Button_sel[2]==1 then
					zoom=4
				elseif Button_sel[2]==2 then
					zoom=4
					down=4
				end
			end
			if not b.noframe then
				gc.rectangle("line",b[2]-b[4]*.5-zoom,b[3]-b[5]*.5-zoom+down,b[4]+2*zoom,b[5]+2*zoom,8)
			end
			mStr(b[1],b[2],b[3]-s*.5-6+down)
		end
	end
end

local function beautiful(s)
	for i=1,3 do
		if abs(byte(s,i)-byte(s,i+1))==1 then return nil end
	end
	return true
end
local function randomInput(time)
	local t
	repeat
		local l={1,2,3,4,5,6,7,8,9,0}
		t=""
		for _=1,4 do
			t=t..rem(l,rnd(#l))
		end
	until beautiful(t)
	input=t
	guess()
	if time==2 then
		repeat
			local l={1,2,3,4,5,6,7,8,9,0}
			t=""
			for _=1,4 do
				t=t..rem(l,rnd(#l))
			end
		until beautiful(t)and t~=sub(info[1],1,4)
		input=t
		guess()
	end
end
local function haveEqual(N)
	for i=1,3 do for j=i+1,4 do
		if byte(N,i)==byte(N,j)then return true end
	end end
end
local function haveGuessed()
	for i=1,#info do
		if input==sub(info[i],1,4)then
			return true
		end
	end
end
local function comp(T,X)
	local A,B=0,0
	for i=1,4 do
		if byte(T,i)==byte(X,i)then
			A=A+1
		else
			local I=byte(T,i)
			for j=1,4 do
				if I==byte(X,j)then B=B+1 break end
			end
		end
	end
	return A,B
end
local function check(X)
	local A,B
	if time==1 then
		if mode==1 then
			local s={0,1,2,3,4,5,6,7,8,9}
			L={""}
			for i=1,4 do
				L[1]=L[1]..rem(s,rnd(11-i))
			end
			if L[1]~=X then
				A,B=comp(L[1],X)
				info[1]=X.."  "..A.."A"..B.."B"

				stat.playing=1
				savedata()--Game started flag
			else
				win()
			end
			return nil
		end
		local c=0
		for i=1,4 do
			c=c+1
			i=sub(X,i,i)+0
			for j=0,9 do if not find(X,j)then
				for k=0,9 do if not find(X,k)and k~=j then
					for l=0,9 do if not find(X,l)and l~=k and l~=j then
						if c~=1 then ins(L,i..j..k..l)end
						if c~=2 then ins(L,j..i..k..l)end
						if c~=3 then ins(L,j..k..i..l)end
						if c~=4 then ins(L,j..k..l..i)end
					end end
				end end
			end end
		end
		info[1]=X.."  0A1B"
		if mode==2 then
			stat.playing=mode
			savedata()
		end--Game started flag
	elseif #L>1 then
		local mat={}for i=0,20 do mat[i]=0 end
		for i=1,#L do
			A,B=comp(L[i],X)
			mat[5*A+B]=mat[5*A+B]+1
		end
		local best,a,b
		if mode==2 then
			local m=0
			for i=0,19 do m=m+mat[i]end
			m=rnd(m)
			for i=0,19 do
				m=m-mat[i]
				if m<=0 then best=i break end
			end
			--Easy mode,choose a bigger class with larger possibility
		else
			local m=0
			best={}
			for i=0,19 do
				if mat[i]>m then
					m=mat[i]
					best={i}
				elseif mat[i]==m then
					ins(best,i)
				end
			end
			best=best[rnd(#best)]
		end
		a,b=int(best*.2),best%5

		for i=#L,1,-1 do
			A,B=comp(L[i],X)
			if B~=b or A~=a then rem(L,i)end
		end
		if mode==5 and time>2 then
			info[#info-1]=gsub(info[#info-1],".A.B","?A?B")
		end
		if mode==3 and #L==1 then
			ins(info,X.."  "..a.."A"..b.."B*")
			SFX("hint")
		else
			ins(info,X.."  "..a.."A"..b.."B")
		end
	else
		if L[1]~=X then
			A,B=comp(L[1],X)
			ins(info,X.."  "..A.."A"..B.."B")
		else
			win()
		end
	end
end



function reset()
	game=0--0=playing,1=win,2=lost
	input,time="",0
	remain=par_time[mode]
	info,L={mode=="Standard"and"Number generated."or"Number generated(sure!)"},{}
	mes=false
	tagMenu=false
	tagList=tagList or{{},{},{},{}}
	for i=1,4 do
		for j=1,10 do
			tagList[i][j]=true
		end
	end
	if mode==3 then randomInput(1)
	elseif mode==4 or mode==5 then randomInput(2)
	end
	if mode>2 then
		stat.playing=mode
		savedata()
	end--Game started flag
	collectgarbage()
end
function charin(i)
	if game==0 and #input<4 then
		input=input..i
		mes=false
	end
	SFX(i)
	SFX("click")
end
function backspace()
	if game==0 and #input>0 then
		SFX("del_"..(5-#input))
		input=sub(input,1,-2)
		mes=false
	end
end
function changeTag(x,y)
	x,y=int((x-20)/170)+1,int((y-650)/60)+1
	if x>0 and x<5 and y>0 and y<11 then
		tagList[x][y]=not tagList[x][y]
		SFX("sweep")
		VIB(.02)
	end
end
function guess()
	if game>0 then return nil end
	if #input<4 then
		mes="4 numbers!"
		SFX("error")
	elseif haveEqual(input)then
		mes="Avoid equal!"
		SFX("error")
	elseif haveGuessed()then
		mes="Guessed this!"
		SFX("error")
	else
		mes=false
		time=time+1
		remain=remain-1
		check(input)
		if remain==0 and game==0 then
			lose()
		elseif game==0 then
			input=""
		end
		SFX("check")
	end
end
function win()
	mes,game="You win!",1
	ins(info,input.."  4A0B")
	winRow=winRow+1
	stat[cur[mode]]=winRow
	stat.playing=0

	Button=Button_play_end
	SFX("win")
	VIB(.15)
	local k=row[mode]
	stat[k]=max(stat[k],winRow)
	if winRow==5 then
		k=cup[mode]
		if not stat[k]then
			stat[k]=true
			Button=Button_play_trophy
		end
	end
	savedata()
end
function lose()
	mes,game="You lost!",2
	ins(info,"Ans:"..L[rnd(#L)])
	stat[cur[mode]]=0
	stat.playing=0

	Button=Button_play_end
	SFX("lose")
	VIB(.15)
	savedata()
end

function askBack(start,target,message)
	Button=Button_backmenu
	scene="backmenu"
	backInfo={start,target,message}
end
function menu()
	winRow=0
	scene="menu"
	Button=Button_menu
	BGM("title")
end
function play(newgame)
	scene="play"
	BGM(mode<4 and "main"or"main2")
	if newgame then reset()end
	winRow=stat[cur[mode]]
	Button=game==0 and(tagMenu and Button_play_2 or Button_play_1)or Button_play_end
end
function winCup()
	scene="trophy"
	BGM("trophy")
	Button=Button_gettrophy
	SFX("win")
end
function trophy(m)
	scene="trophy"
	mode=m
	BGM("trophy")
	Button=Button_trophy
	SFX("win")
end

function love.keypressed(i)
	frameUpdate=true
	if scene=="play"then
		if #i==1 and byte(i)>47 and byte(i)<58 then
			charin(i)
		elseif i=="return"then
			guess()
		elseif i=="backspace"then
			backspace()
		elseif i=="escape"then
			if game==0 and time>0 then
				askBack(play,menu,"Back to menu?")
			else

				menu()
			end
		end
	elseif scene=="menu"then
		if i=="escape"then
			askBack(menu,"quit","Quit game?")
		end
	end
end
function love.mousemoved(x,y)
	frameUpdate=true
	x,y=convert(x,y)
	Button_sel[1]=nil
	for i=1,#Button do
		local b=Button[i]
		if(not b.hide or b.hide and not b.hide())and x>b[2]-b[4]*.5 and x<b[2]+b[4]*.5 and y>b[3]-b[5]*.5 and y<b[3]+b[5]*.5 then
			Button_sel[1]=b
			Button_sel[2]=Button_sel[2]==2 and 2 or 1
			break
		end
	end--Alther:[rownumber]
	if not Button_sel[1]then Button_sel[2]=0 end
end
function love.mousepressed(x,y,b,t)
	frameUpdate=true
	x,y=convert(x,y)
	if b==1 and not t then
		if Button_sel[2]==1 then
			Button_sel[2]=2
		end
		if scene=="play"and tagMenu then
			changeTag(x,y)
		end
	end
end
function love.mousereleased(x,y,b,t)
	frameUpdate=true
	if b==1 and not t then
		if Button_sel[2]==2 then
			Button_sel[2]=1
			Button_sel[1][6]()
			if not Button_sel[1].noframe then VIB(.03)end
		end
		love.mousemoved(x,y)
	end
end

function love.touchmoved(_,x,y)
	frameUpdate=true
	love.mousemoved(x,y)
	if not Button_sel[1]then
		touching=nil
	end
end
function love.touchpressed(id,x,y)
	frameUpdate=true
	if #love.touch.getTouches()==1 then
		touching=id
		love.mousemoved(x,y)
		if scene=="play"and tagMenu then
			changeTag(convert(x,y))
		end
	end
end
function love.touchreleased(id,x,y)
	frameUpdate=true
	if id==touching then
		touching=nil
		if Button_sel[1]then
			love.mousepressed(x,y,1)
			love.mousereleased(x,y,1)
		end
		Button_sel[1]=nil
		Button_sel[2]=0
	end
end

function love.resize(w,h)
	screenK=1280/h
	screenM=(w-h*720/1280)/2
	gc.origin()
	gc.translate(screenM,0)
	gc.scale(1/screenK,1/screenK)
end
function love.draw()
	if scene=="play"then
		drawButton()
		gc.setColor(1,1,1)
		setFont(60)
		mStr(modes[mode],360,15)--Mode
		setFont(35)
		for i=1,#info do
			if i<11 then
				gc.print(info[i],40,40*i+80)
			elseif i<21 then
				gc.print(info[i],270,40*i-320)
			else
				gc.print(info[i],500,40*i-720)
			end
		end--Information
		if winRow>0 then
			gc.print("row:",20,55)
			gc.print(winRow,93,58)
		end
		gc.rectangle("line",20,100,680,440)--Frame

		if mes and not tagMenu then mStr(mes,360,640)end--Message
		if game==0 then gc.print(remain,465,600)end--Remain
		setFont(60)
		gc.print(input,285,560)--Input
		gc.rectangle("line",260,560,200,70)--Input frame

		if tagMenu then
			for i=0,4 do
				gc.line(20+170*i,650,20+170*i,1250)
			end
			setFont(52)
			gc.line(20,650+600,700,650+600)
			for i=0,9 do
				gc.line(20,650+60*i,700,650+60*i)
				for j=1,4 do
					if tagList[j][i+1]then
						gc.print(i,170*j-78,650+60*i)
					end
				end
			end
		end
	elseif scene=="menu"then
		drawButton()
		gc.setColor(1,1,1)
		gc.draw(img.music,480-32,60-32)
		gc.draw(img.sound,570-32,60-32)
		gc.draw(img.vibrate,660-32,60-32)
		if not setting.bgm then gc.draw(img.off,480-32,60-32)end
		if not setting.sfx then gc.draw(img.off,570-32,60-32)end
		if not setting.vib then gc.draw(img.off,660-32,60-32)end
		setFont(90)
		mStr("Try Guess It!",360,130)
		if system==2 then
			setFont(40)
			gc.print("Android Version",360,220)
		end
		setFont(50)
		mStr("V1.4   Powered by Love2d",360,1180)
		setFont(35)
		mStr("By MrZ   1046101471@qq.com",360,1130)
		for i=1,5 do
			gc.setColor(modeColor[i])
			if stat[cup[i]]then
				gc.draw(img[cup[i]],110,300+100*i,nil,4,nil,10,10)
			end
			if stat[row[i]]>0 then
				gc.print(stat[cur[i]],570,260+100*i)
				gc.print(stat[row[i]],570,300+100*i)
			end
		end
	elseif scene=="backmenu"then
		drawButton()
		setFont(70)
		gc.setColor(1,1,1)
		mStr(backInfo[3],360,400)
	elseif scene=="trophy"then
		drawButton()
		setFont(60)
		gc.setColor(1,1,1)
		mStr(trophy_text[mode],360,250)
		gc.setColor(modeColor[mode])
		gc.draw(img[cup[mode]],360,600,nil,20,nil,10,10)
	end
end
function love.focus(f)
	if f then
		frameUpdate=true
		if bgmPlaying then bgm[bgmPlaying]:play()end
	else
		if bgmPlaying then bgm[bgmPlaying]:pause()end
	end
end
function love.run()
	frameUpdate=true
	love.resize(nil,gc.getHeight())
	math.randomseed(os.time()*626)
	gc.setLineWidth(3)
	return function()
		love.event.pump()
		for name,a,b,c,d,e,f in love.event.poll()do
			if name=="quit"then return 0 end
			love.handlers[name](a,b,c,d,e,f)
		end
		if frameUpdate then
			gc.clear()
			love.draw()
			gc.present()
			frameUpdate=false
		end
	end
end

menu()