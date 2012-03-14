'This BMX file was edited with BLIde ( http://www.blide.org )
Const CLOG = False

'list of all non-static sources
Global _sources:T3DSoundSource
rem
	bbdoc: Sound source class. Every sound played, is played by a T3DSoundSource.
end rem
Type T3DSoundSource
	Field _succ:T3DSoundSource, _id, _seq, _sound:T3DSound
	rem
		bbdoc: Returns TRUE if this 3D sound source is playing any sound.
	end rem
	Method Playing()
		Local st
		alGetSourcei _id, AL_SOURCE_STATE, Varptr st
		Return st = AL_PLAYING
	End Method
				
	rem
		bbdoc: Returns TRUE if this 3D sound source is currently paused.
	end rem
	Method Paused()
		Local st
		alGetSourcei _id, AL_SOURCE_STATE, Varptr st
		Return st = AL_PAUSED
	End Method

	rem
		bbdoc: Returns TRUE if this 3D sound source is active
		about:
		Returns TRUE if this sound source is playing sound or is paused but not completelly stopped. Otherwise returns FALSE
	end rem
	Method Active()
		Local st
		alGetSourcei _id, AL_SOURCE_STATE, Varptr st
		Return st = AL_PLAYING Or st = AL_PAUSED
	End Method
	
End Type

rem
	bbdoc: This function returns a list (string array) of all avaiable sound devices.
end rem
Function Enum3DSoundDevices:String[] ()
	Local p:Byte Ptr = alcGetString(0, ALC_DEVICE_SPECIFIER)
	If Not p Return
	Local devs:String[100], n
	While p[0] And n < 100
		Local sz
		Repeat
		sz:+1
		Until Not p[sz]
		devs[n] = String.FromBytes(p, sz)
		n:+1
		p:+sz + 1
	Wend
	Return devs[..n]
End Function

rem
	bbdoc: Any sound loaded in the Sound3D module, is a T3DSound.
end rem
Type T3DSound Extends TSound
	Field _IsMono:Int = False
	rem
		bbdoc: This method returns TRUE if the sound can be properly emited in the 3D space.
		about:
		Usually, stereo sounds are not compatible with space localization. this method will tell if the loaded sound is not 3D-compatible.
	end rem
	Method Is3DCompatible:Int()
		Return _IsMono
	End Method
	Method Delete()
		alDeleteBuffers 1, Varptr _buffer
		If CLOG WriteStdout "Deleted OpenAL buffer~n"
	End Method

	Method Play:T3DChannel(alloced_channel:TChannel = Null)
		Local t:T3DChannel = Cue(alloced_channel)
		t.SetPaused False
		Return t
	End Method

	Method Cue:T3DChannel(alloced_channel:TChannel = Null)
		Local t:T3DChannel = T3DChannel(alloced_channel)
		If t
			Assert t._static
		Else
			t = T3DChannel.Create(False)
		EndIf
		t.Cue Self
		Return t
	End Method

	Function Create:T3DSound(sample:TAudioSample, flags)
		Local alfmt
		Local mono:Int = False
		Select sample.format
			Case SF_MONO8
				alfmt = AL_FORMAT_MONO8
				mono = True
			Case SF_MONO16LE
				alfmt = AL_FORMAT_MONO16
				?BigEndian
				sample = sample.Convert(SF_MONO16BE)
				?
				mono = True
				
			Case SF_MONO16BE
				alfmt = AL_FORMAT_MONO16
				?LittleEndian
				sample = sample.Convert(SF_MONO16LE)
				?
				mono = True
			Case SF_STEREO8
				alfmt = AL_FORMAT_STEREO8
			Case SF_STEREO16LE
				alfmt = AL_FORMAT_STEREO16
				?BigEndian
				sample = sample.Convert(SF_STEREO16BE)
				?
			Case SF_STEREO16BE
				alfmt = AL_FORMAT_STEREO16
				?LittleEndian
				sample = sample.Convert(SF_STEREO16LE)
				?
		End Select
		Local buffer
		alGenBuffers 1, Varptr buffer
		If CLOG WriteStdout "Generated 3D buffer~n"
		alBufferData buffer, alfmt, sample.samples, sample.length * BytesPerSample[sample.format], sample.hertz
		Local t:T3DSound = New T3DSound
		t._IsMono = mono
		t._buffer = buffer
		If (flags & 1) t._loop = 1
		Return t
	End Function

	Field _buffer, _loop

End Type

Type T3DChannel Extends TChannel

	Method Delete()
		If _seq <> _source._seq Return
		If _source.Paused() alSourceStop _source._id
		If _static
			_source._succ = _sources
			_sources = _source
		EndIf
	End Method

	Method Stop()
		If _seq <> _source._seq Return
		alSourceStop _source._id
		_source._seq:+1	'doesn't hurt...
		If _static
			_source._succ = _sources
			_sources = _source
		EndIf
	End Method
	
	Method SetPaused(paused)
		If _seq <> _source._seq Return
		If paused alSourcePause _source._id Else alSourcePlay _source._id
	End Method
	
	Method SetVolume(volume:Float)
		If _seq <> _source._seq Return
		alSourcef _source._id, AL_GAIN, volume
	End Method
	
	Method SetPan(pan:Float)
		If _seq <> _source._seq Return
		pan:*90
		alSource3f _source._id, AL_POSITION, Sin(pan), 0, -Cos(pan)
	End Method
	
	Method SetDepth(depth:Float)
		If _seq <> _source._seq Return
	End Method
	
	Method SetRate(rate:Float)
		If _seq <> _source._seq Return
		alSourcef _source._id, AL_PITCH, rate
	End Method
	
	Method Playing()
		If _seq <> _source._seq Return
		Return _source.Active()
	End Method

	Method Cue(sound:T3DSound)
		If _seq <> _source._seq Return
		_source._sound = sound
		alSourcePause _source._id
		alSourcei _source._id, AL_LOOPING, sound._loop
		alSourcei _source._id, AL_BUFFER, sound._buffer
	End Method
	
	Function Create:T3DChannel(static)
		Local source:T3DSoundSource = _sources, pred:T3DSoundSource = Null
		While source
			Local st
			alGetSourcei source._id, AL_SOURCE_STATE, Varptr st
			If st = AL_STOPPED
				source._seq:+1
				source._sound = Null
				If pred pred._succ = source._succ Else _sources = source._succ
				Exit
			EndIf
			pred = source
			source = source._succ
		Wend
		If Not source
			source = New T3DSoundSource
			alGenSources 1, Varptr source._id
			If CLOG WriteStdout "Generated OpenAL Source~n"
			alSourcei source._id, AL_SOURCE_RELATIVE, True
		EndIf
		alSourcef source._id, AL_GAIN, 1
		alSourcef source._id, AL_PITCH, 1
		alSource3f source._id, AL_POSITION, 0, 0, 1
		If Not static
			source._succ = _sources
			_sources = source
		EndIf
		Local t:T3DChannel = New T3DChannel
		t._source = source
		t._seq = source._seq
		t._static = static
		Return t
	End Function
	
	Field _source:T3DSoundSource, _seq, _static
	
End Type

Type T3DAudioDriver Extends TAudioDriver

	Method Name:String()
		Return _name
	End Method
	
	Method Startup()
		_device = 0
		If _devname
			_device = alcOpenDevice(_devname)
		Else If OpenALInstalled()
			_device = alcOpenDevice(Null)
			If Not _device
				_device = alcOpenDevice("Generic Hardware")
				If Not _device
					_device = alcOpenDevice("Generic Software")
				EndIf
			EndIf
		EndIf
		If _device
			_context = alcCreateContext(_device, Null)
			If _context
				alcMakeContextCurrent _context
				alDistanceModel AL_INVERSE_DISTANCE_CLAMPED
				Return True
			EndIf
			alcCloseDevice(_device)
		EndIf
	End Method
	
	Method Shutdown()
		alcDestroyContext _context
		alcCloseDevice _device
	End Method

	Method CreateSound:T3DSound(sample:TAudioSample, flags)
		Return T3DSound.Create(sample, flags)
	End Method
	
	Method AllocChannel:T3DChannel()
		Return T3DChannel.Create(True)
	End Method
	
	Function Create:T3DAudioDriver(name:String, devname:String)
		Local t:T3DAudioDriver = New T3DAudioDriver
		t._name = name
		t._devname = devname
		Return t
	End Function
	
	Field _name:String, _devname:String, _device, _context

End Type

If OpenALInstalled() T3DAudioDriver.Create "Audio3D", ""

Rem
bbdoc: Enable OpenAL Audio
returns: True if successful
about:
After successfully executing this command, OpenAL audio drivers will be added
to the array of drivers returned by #AudioDrivers.
End Rem
Function Enable3DSound()
	Global done, okay
	If done Return okay
	If OpenALInstalled() And alcGetString
		For Local devname:String = EachIn Enum3DSoundDevices()
			T3DAudioDriver.Create("Audio3D " + devname, devname)
		Next
		T3DAudioDriver.Create "Audio3D Default", String.FromCString(alcGetString(0, ALC_DEFAULT_DEVICE_SPECIFIER))
		okay = True
	EndIf
	done = True
	Return okay
End Function
