'
' Build on a few examples in the BrightSign documentation to explore the
' integration of Node.js and the BrightSign JavaScript API.
'

'
' Platform initialization functions.  Although this setup could be done in
' JavaScript, it is more closely related to the platform than the
' application, so keep it separate.
'
sub setupDWS()
    registrySection = CreateObject("roRegistrySection", "networking")
    dwsp = registrySection.read("dwsp")
    print "BS> dwsp: "; dwsp

	dws = CreateObject("roAssociativeArray")
	dws["port"] = "80"
	dws["password"] = registrySection.read("dwsp")
                
    nc = CreateObject("roNetworkConfiguration", 0)
    if type(nc) = "roNetworkConfiguration" then
		dwsRebootRequired = nc.SetupDWS(dws)
		if dwsRebootRequired then
            print "BS> Want to reboot for DWS, but will not"
            'RebootSystem()
        else
            print "BS> DWS set up"
        end if
    else
        print "BS> Unable to set up DWS"
	end if
end sub

sub setVideoMode(mode)
    videoMode = CreateObject("roVideoMode")
    ok = videoMode.setMode(mode)
    if ok then
        print "BS> Set video mode to "; mode
    else
        print "BS> Unable to set video mode to "; mode
    end if
end sub

'
' Set up the platform and launch the application.
'
sub Main()
    setupDWS()
    setVideoMode("1280x800x60p")
    ' TODO: set audio config or output?

    finished = false
    mp = CreateObject("roMessagePort")

    ' Adapted from https://docs.brightsign.biz/display/DOC/roHtmlWidget
    ' and https://docs.brightsign.biz/display/DOC/Node.js

    rect = CreateObject("roRectangle", 0, 0, 1280, 800)
    inspector_server = {
        port: 2999
    }
    ' For audio from HTML elements, consider
    ' pcm_audio_outputs
    ' compressed_audio_outputs
    ' multi_channel_audio_outputs

    htmlAudio = CreateObject("roAudioOutput", "hdmi")
    usbAudio = CreateObject("roAudioOutput", "usb")
    spdifAudio = CreateObject("roAudioOutput", "spdif")
    analogAudio = CreateObject("roAudioOutput", "analog")
    ' pcm_audio_outputs = [htmlAudio, usbAudio, spdifAudio, analogAudio]
    ' pcm_audio_outputs = ["hdmi", "usb", "spdif", "analog"]
    ' pcm_audio_outputs = ["hdmi"]
    ' pcm_audio_outputs = ["hdmi-4"]
    ' compressed_audio_outputs = [htmlAudio, usbAudio, spdifAudio, analogAudio]
    ' multi_channel_audio_outputs = [htmlAudio, usbAudio, spdifAudio, analogAudio]
    compressed_audio_outputs = ["hdmi", "hdmi-1", "hdmi-2", "hdmi-3", "hdmi-4", "usb", "spdif", "analog"]

    config = {
        ' pcm_audio_outputs: pcm_audio_outputs
        ' compressed_audio_outputs: compressed_audio_outputs
        ' multi_channel_audio_outputs: multi_channel_audio_outputs
        nodejs_enabled: true
        mouse_enabled: true
        scrollbar_enabled: true
        inspector_server: inspector_server
        brightsign_js_objects_enabled: true
        port: mp
        url: "file:///SD:/test/test.html"
        security_params: {websecurity: false}
    }
    html = CreateObject("roHtmlWidget", rect, config)
    'sleep(5000)
    html.show()

    ' Adapted from https://docs.brightsign.biz/display/DOC/messageport
    ' and https://docs.brightsign.biz/display/DOC/roNodeJsEvent

    while not finished
        ev = mp.WaitMessage(30000)
        if ev = invalid then
            print "BS> Timed out waiting for a message"
        else if type(ev) <> "roHtmlWidgetEvent" then
            print "BS> Received unexpected message type: "; type(ev)
        else
            eventData = ev.GetData()
            print "BS> >>>"; eventData; "<<<"
            if type(eventData) = "roAssociativeArray" and type(eventData.reason) = "roString" then
                print "BS> Reason: "; eventData.reason
                if eventData.reason = "process_exit" then
                    print "BS> Node.js instance exited with code "; eventData.exit_code
                    finished = true
                else if eventData.reason = "load-started" then
                    print "BS> HTML load started"
                else if eventData.reason = "load-finished" then
                    print "BS> HTML load finished for "; eventData.url
                else if eventData.reason = "message" then
                    print "BS> Message: "; eventData.message
                    if eventData.message.complete = invalid then
                        if eventData.message.who = invalid then
                            print "BS> Not sure what kind of message this is: "; eventData.message
                        else
                            print "BS> Hello, "; eventData.message.who
                        end if
                    else if eventData.message.complete = "true" then
                        'finished = true
                        if eventData.message.result = "PASS" then
                            print "BS> Test passed"
                        else
                            print "BS> Test failed: "; eventData.message.err
                        end if
                    end if
                else
                    print "BS> Unexpected reason: "; eventData.reason
                end if
            else
                print "BS> Unexpected eventData: "; type(eventData)
            end if
        end if

        html.PostJSMessage({ Reason: "probe", Message: "purple box" })

    end while

    print "BS> Exit Main"
end sub
