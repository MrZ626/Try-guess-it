function love.conf(t)
    local X=nil
    t.audio.mixwithsystem=true--Switch on to keep background music playing
    t.identity="Tryguessit"
    t.appendidentity=X
    t.console=X
    t.accelerometerjoystick=X
    t.version="11.1"
    t.gammacorrect=X

    t.window.title="Try guess it V1.3"
    t.window.icon="title.png"
    t.window.width=432
    t.window.height=768
    t.window.borderless=X
    t.window.resizable=true
    t.window.minwidth=360
    t.window.minheight=640
    t.window.vsync=1
    t.window.msaa=X
    t.window.depth=X
    t.window.stencil=X
    t.window.display=1
    t.window.highdpi=X

    t.modules.audio=true
    t.modules.event=true
    t.modules.font=true
    t.modules.graphics=true
    t.modules.image=true
    t.modules.keyboard=true
    t.modules.mouse=true
    t.modules.sound=true
    t.modules.system=true
    t.modules.touch=true
    t.modules.window=true
    t.modules.filesystem=true

    t.modules.math=X
    t.modules.data=X
    t.modules.joystick=X
    t.modules.physics=X
    t.modules.thread=X
    t.modules.timer=X
    t.modules.video=X
end