'This BMX file was edited with BLIde ( http://www.blide.org )

'Init the sound engine
s3DSoundEngine.Init()

rem
	bbdoc: This shared class handles some basic operations of the Sound3D module
end rem
Type s3DSoundEngine Abstract

	Function Init()
		Enable3DSound()
		
		Local drives:String[] = Audio3DDrives()
		
		For Local S:String = EachIn drives
			If S = "Audio3D Default" Then
				SetAudioDriver(S)
			End If
		Next
		'alDistanceModel AL_INVERSE_DISTANCE_CLAMPED
	End Function
	
	rem
		bbdoc: This function loads a sound file and stores it on a T3DSound class instance.
		returns: The T3DSound object that has been created, if the load process succeeds.
	end rem
	Function LoadSound:T3DSound(url:Object, flags:Int = 0)
		Local T3DS:T3DSound = T3DSound.Create(LoadAudioSample(url) , flags)
		?Debug
			If T3DS <> Null Then
				If T3DS._IsMono = False Then
					If url.ToString().Length < 255 Then
						StandardIOStream.WriteLine("debug Important: Loading an audio sample not compatible with 3D positioning: " + url.ToString())
						StandardIOStream.Flush()
					Else
						StandardIOStream.WriteLine("debug Important: Loading an audio sample not compatible with 3D positioning.")
					EndIf
				End If
			End If
		?
		Return T3DS
	End Function
	
	rem
		bbdoc: Returns a list (string array) of all the available 3D sound devices.
		returns: A one dimension array of strings containing the generated list of devices.
	end rem
	Function Audio3DDevices:String[] ()
		Local Dev:String[256]
		'Local All:String[] = AudioDrivers()
		Local index:Int = 0
		
		Local Drives:String[] = AudioDrivers()

		For Local Drive:String = EachIn Drives
			If Drive.Find("Audio3D") <> - 1 Then
				Dev[Index] = Drive
				Index:+1
			EndIf
		Next
		
		Return Dev[..index]
	End Function
	
	rem
		bbdoc: Set a speciffic 3D sound device.
	end rem
	Function SetAudio3DDriver(Driver:String)
		If Driver.Find("Audio3D") = -1 Then Throw "Invalid 3DSound Driver"
		SetAudioDriver(Driver)
	End Function
		
End Type

Private
Global Emits:TList = New TList

Function ListenerHook:Object(id, data:Object, context:Object)
	'If Listener <> Null Then
		sListener3D.Update()
	'End If
	
	'Local IDS:Int[100]
	'Local Index:Int = 0
	For Local E:TSource3D = EachIn Emits
		E.Update()
		If E.isPlaying() = False And E.Loop = False Then
			Emits.Remove(E)
		EndIf
	Next
End Function
AddHook FlipHook, ListenerHook
Public

REM
	bbdoc: Shared class that provides the needed methods to manipulate the global listener object of the Sound3D module
	about:
	Every sound in this module is played in relation to the listener. The sound emiters (TSource3D) that are far of the listener do sound quieter, and the ones that are closer sound louder. Also the panning L-R and doppler effect is calculated assuming the listener position as the "center" of the acoustic field.
	In this module, only ONE listener is allowed, so this class is not instanciable, everything can be done using directly the class built-in functions.
END REM
Type sListener3D Abstract
	Global ent:TEntity
	Global atDummy:TEntity
	Global upDummy:TEntity
	rem
		bbdoc: This scale factor (by default 1) is used to scale distances, so a higher scale factor will make far objects sound even farer, and near objects will sound even closer.
	end rem
	Global ScaleFactor:Float = 1
	rem
		bbdoc: This function associates the audio listener to a minib3d entity.
		about:
		The audio listener will be set always at the same location as the paramter entity. Moving and rotating this entity, will also move and rotate the listener, and affect the sound.
		In other words, once this function is called, the target minib3d entity is the listener.
	end rem
	Function TargetEntity(ent:TEntity)
		sListener3D.ent = ent
		
		Local tempX:Float = EntityX(ent)
		Local tempY:Float = EntityY(ent)
		Local tempZ:Float = EntityZ(ent)
		
		Local tempRX:Float = EntityYaw(ent)
		Local tempRY:Float = EntityPitch(ent)
		Local tempRZ:Float = EntityRoll(ent)
		
		PositionEntity(ent, 0, 0, 0)
		RotateEntity(ent, 0, 0, 0)
			If atDummy <> Null Then FreeEntity(atDummy)
			If upDummy <> Null Then FreeEntity(upDummy)
			atDummy = CreatePivot()
			upDummy = CreatePivot()
		
		MoveEntity(sListener3D.atDummy, 0, 0, 1)
		MoveEntity(sListener3D.upDummy, 0, 1, 0)
		
		EntityParent(sListener3D.atDummy, ent)
			EntityParent(sListener3D.upDummy, ent)
		
			PositionEntity(ent, tempX, tempY, tempZ)
		RotateEntity(ent, tempRX, tempRY, tempRZ)
	End Function
	
	Function Update()
		If ent <> Null Then
			alListener3f(AL_POSITION, EntityX(ent, True) , EntityY(ent, True) , EntityZ(ent, True))
			Rem
			Local Euler:Float[3]
			Euler[0] = -EntityYaw(ent,True) * Pi / 180.0
			Euler[1] = EntityPitch(ent,True) * Pi / 180.0
			Euler[2] = EntityRoll(ent , True) * Pi / 180.0
			End Rem
			Local O:Float[6]
			'at
			O[0] = EntityX(ent, True) - EntityX(atDummy, True)
			O[1] = EntityY(ent, True) - EntityY(atDummy, True)
			O[2] = EntityZ(ent, True) - EntityZ(atDummy, True)
			'up
			O[3] = EntityX(ent, True) - EntityX(upDummy, True)
			O[4] = EntityY(ent, True) - EntityY(upDummy, True)
			O[5] = EntityZ(ent, True) - EntityZ(upDummy, True)

			
			alListenerfv(AL_ORIENTATION, O)
		EndIf
	End Function
	
'	Function _DrawDebug(Y:Float = 20)
'		Local O:Float[6]
'		'at
'		O[0] = EntityX(ent, True) - EntityX(atDummy, True)
'		O[1] = EntityY(ent, True) - EntityY(atDummy, True)
'		O[2] = EntityZ(ent, True) - EntityZ(atDummy, True)
'		'up
'		O[3] = EntityX(ent, True) - EntityX(upDummy, True)
'		O[4] = EntityY(ent, True) - EntityY(upDummy, True)
'		O[5] = EntityZ(ent, True) - EntityZ(upDummy, True)
'
'		DrawText "at-Vector: " + o[0] + ":" + o[1] + ":" + O[2], 20, Y
'		DrawText "up-Vector: " + o[3] + ":" + o[4] + ":" + O[5], 20, Y + 20
'	End Function
		
		
End Type

rem
	bbdoc: This class is the basic sound emiter class. 
	about: 
	Any sound played on Sound3D, is being played by a TSouce3D object, and listened by the Listener3D object.<br>
	See also #Load3DSound #EmitSound and #PlayMusic	
end rem
Type TSource3D
	Field Source:TEntity
	Field Sound:T3DChannel
	Field Channel:T3DChannel
	Field Loop:Byte = False
	Field _logicalvolume:Float = 1.0

	rem
		bbdoc: This function creates a new TSource3D instance, and returns it.
		about: 
		When using this method, the internal OpenAL channel is created as 'static'.
		for regular use it is recommended to create the #TSource3D object using the #PlayMusic function or the #EmitSound function.
	end rem
	Function Create:TSource3D(ent:TEntity)
		Local S:TSource3D = New TSource3D
		S.Sound = T3DChannel.Create(True)
		S.Source = Ent
		Return S
	End Function
	
	rem
		bbdoc: Set the 3D speed vector of this Source3D
		about:
		If this sound source is attached to a moving entity on minib3d, you can set its speed 3D vector in order to get an accurate and reallistic doppler effect
	end rem
	Method SetSpeedVector(X:Float, Y:Float, Z:Float)
		If channel = Null Then Throw "Can't set the speed vector for a null audio source!"
		alSource3f(T3DChannel(Channel)._source._id, AL_VELOCITY, X, Y, Z)
	End Method
	
'	rem
'		bbdoc: Plays a sound discarding any 3D information.
'		about: 
'		Using this function, the sound will be played ignoring any 3D aspect. 
'		This is the method used to play background music.
'	end rem
	Method Play:T3DChannel(_Sound:T3DSound, Loop:Byte = False)
		If channel <> Null Then free()
		Channel = _Sound.Play(Sound)
		'alSourcei Channel._Source._id,AL_SOURCE_RELATIVE,AL_TRUE
		alSource3f(T3DChannel(Channel)._source._id, AL_VELOCITY, 0, 0, 0)
		'		alSourcei(T3DChannel(Channel)._source._id , AL_SOURCE_RELATIVE , False)
		alSourcei(T3DChannel(Channel)._source._id, AL_SOURCE_RELATIVE, False)
		alSourcef T3DChannel(Channel)._source._id, AL_MIN_GAIN, 0.0
		alSourcef T3DChannel(Channel)._source._id, AL_MAX_GAIN, 100.0
		If Loop = True Then
			alSourcei (Channel._Source._id, AL_LOOPING, AL_TRUE)
		EndIf
		Emits.Addlast(Self)
		Self.Loop = Loop
		Return Channel
	End Method
	
	rem
		bbdoc: Enables or disables the "Paused" status of a TSound3D object.
	end rem
	Method Pause(Paused:Int = True)
		If Self.Channel <> Null Then Self.Channel.SetPaused(Paused:Int) Else Throw "There's no loaded sound to pause."
	End Method
	rem
		bbdoc: This method let's you modify the rate of the sound being played. 
	end rem
	Method SetRate(Rate:Float)
		If Self.channel <> Null Then Self.Channel.SetRate(Rate:Float) Else Throw "There's no channel to modify the rate."
	End Method
	
	
	rem
		bbdoc: This method free the resources associated to this object, and also stops sound reproduction.
	end rem
	Method Free()
		Emits.Remove(Self)
		If channel <> Null Then channel.Stop()
		Source = Null
		Channel = Null
	End Method

	
	rem
		bbdoc: Plays a sound discarding any 3D information.
		about: 
		Using this function, the sound will be played ignoring any 3D aspect. 
		This is the method used to play background music.
	end rem
	Method PlayMusic(_Sound:T3DSound, Loop:Byte = False)
		Channel = _Sound.Play(Sound)
		'alSourcei Channel._Source._id,AL_SOURCE_RELATIVE,AL_TRUE
		alSource3f T3DChannel(Channel)._source._id, AL_VELOCITY, 0, 0, 0
		alSourcef T3DChannel(Channel)._source._id, AL_MIN_GAIN, 0.0
		alSourcef T3DChannel(Channel)._source._id, AL_MAX_GAIN, 1.0

		If Loop = True Then
			alSourcei (Channel._Source._id, AL_LOOPING, AL_TRUE)
		EndIf
		Emits.Addlast(Self)
		Self.Loop = Loop
	End Method

	rem
		bbdoc: Returns TRUE if the TSource3D sound is being played
	end rem
	Method isPlaying:Byte()
		If channel = Null Then Return False Else Return Channel.Playing()
	End Method
	
	Method SetPosition(V:TVector)
		If Channel = Null Then Return
		alSource3f T3DChannel(Channel)._source._id, AL_POSITION, V.X, V.Y, V.Z
	End Method
	
	Method Update()
		If Channel <> Null And Source <> Null Then
			Try
				SetPosition(TVector.Create(EntityX(Source, True) , EntityY(Source, True) , EntityZ(Source, True)))
				Local ED:Float = Abs(EntityDistance(source, sListener3D.ent)) * sListener3D.ScaleFactor
				If ed <.5 Then ED =.5
				channel.SetVolume(100:Float * _logicalvolume / ED)
			Catch o:Object
				'DebugStop()	'Somethimes the hook is fired before a died item is collected from the tlist!
			End Try
			'clean resources properly!
			If Self.Channel._source.Active() = False Then Self.Free()
		EndIf
	End Method
	Rem
		bbdoc: Set's the TSource3D object volume.
	end rem
	Method SetVolume(vol:Float = 1.0)
		Channel.SetVolume(vol)
		_logicalvolume = vol
	End Method
	
End Type

rem
	bbdoc: This function is used to make a minib3d entity emit a sound.
	about:
	The referenced Entity will be the sound emiter (the sound will be played FROM the entity location and with the entity orientation).
	A reference to the minib3d entity is stored inside the TSource3D object untill the sound ends playing, the entity is freed (freentity) or TSound3D.Free() method is called.
end rem
Function EmitSound:TSource3D(Sound:T3DSound, Entity:TEntity, Loop:Int = False)
	Local S:TSource3D = TSource3D.Create(Entity)
	S.Play(Sound, Loop)
	s.Channel.SetVolume(0)
	s.SetPosition(TVector.Create(EntityX(entity), EntityY(entity), EntityZ(entity)))
	Return S
End Function

rem
	bbdoc: This function is used to make a minib3d entity emit a sound.
	Returns: A #TSource3D object
end rem
Function PlayMusic:TSource3D(Sound:T3DSound, Loop:Byte = False)
	Local S:TSource3D = TSource3D.Create(sListener3D.ent)
	S.PlayMusic(Sound, Loop)
	Return s
End Function

rem
	bbdoc: This method associates a minib3d entity with the Sound3D listener #sListener3D.
	about: The the associated entity moves or turns, the audio listener will also, so in general terms, after calling this function, the minib3d object IS the listener.
end rem
Function SetListenerTargetEntity(Entity:TEntity)
	sListener3D.TargetEntity(Entity)
End Function

rem
	bbdoc: Returns a list (string array) of all the available 3D sound devices.
	returns: A one dimension array of strings containing the generated list of devices.
end rem
Function Audio3DDrives:String[] ()
	Return s3DSoundEngine.Audio3DDevices()
End Function

rem
	bbdoc: Set a speciffic 3D sound device.
end rem
Function SetAudio3DDriver(Driver:String)
	s3DSoundEngine.SetAudio3DDriver(Driver)
End Function

rem
	bbdoc: This function loads a sound file and stores it on a T3DSound class instance.
	returns: The T3DSound object that has been created, if the load process succeeds.
	about: Be sure to be loading MONO sound if you wish the sound file to be located at the 3D space.
end rem
Function Load3DSound:T3DSound(url:Object, flags:Int = 0)
	Return s3DSoundEngine.LoadSound(url:Object)
End Function




