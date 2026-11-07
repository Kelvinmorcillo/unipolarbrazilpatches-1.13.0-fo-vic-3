Includes = {
	"cw/pdxmesh.fxh"
	"cw/terrain.fxh"
	"cw/camera.fxh"
	"cw/utility.fxh"
	"cw/pdxmesh_buffers.fxh"
	"jomini/jomini_water.fxh"
	"sharedconstants.fxh"
	"harvest_condition.fxh"
}

VertexShader =
{
	TextureSampler WindMapTree
	{
		Ref = WindMapTree
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
	}
	TextureSampler FlowMapTexture
	{
		Ref = JominiWaterTexture2
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
	}
}

PixelShader =
{
	TextureSampler SolLowTexture
	{
		Ref = SolLowTexture
		MagFilter = "Linear"
		MinFilter = "Linear"
		MipFilter = "Linear"
		SampleModeU = "Wrap"
		SampleModeV = "Wrap"
	}
}

struct SStandardMeshUserData
{
	float _CountryIndex;
	float _RandomValue;
	float _PowerBlocIndex;
	float _Padding03;
};

struct SBuildingMeshUserdata
{
	float4 _LightColor;
	float _CountryIndex;
	float _RandomValue;
	float _SolValue;
	float _ShouldLightActivate;

	float _HasCompanyTexture;
	float _PowerBlocIndex;
};

struct SRevolutionMeshUserdata
{
	float _IgColorIndex;
	float _Padding01;
	float _Padding02;
	float _Padding03;
};

struct SShipMeshUserData
{
	float _CountryIndex;
	float _Damage; // = 0.0 - 1.0, where 1.0 is fully destroyed
	float _Padding01;
	float _Padding02;

	float4 _DecalPosition01;
	float4 _DecalPosition02;
	float4 _DecalPosition03;
	float4 _DecalPosition04;
};

struct WaveAnimationSettings
{
	float LargeWaveFrequency;		// Higher values simulates higher wind speeds / more turbulence
	float SmallWaveFrequency;		// Higher values simulates higher wind speeds / more turbulence
	float WaveLenghtPow;			// Higher values gives higher frequency at the end of the flag
	float WaveLengthInvScale;		// Higher values gives higher frequency overall
	float WaveScale;				// Higher values gives a stretchier flag
	float AnimationSpeed;			// Speed
};

Code
[[
	float GetSeed()
	{
		#if defined( HIGH_QUALITY_SHADERS )
			#if defined( SEED_01 )
				return 1;
			#elif defined( SEED_02 )
				return 2;
			#elif defined( SEED_03 )
				return 3;
			#elif defined( SEED_04 )
				return 4;
			#elif defined( SEED_05 )
				return 5;
			#elif defined( SEED_06 )
				return 6;
			#elif defined( SEED_07 )
				return 7;
			#elif defined( SEED_08 )
				return 8;
			#elif defined( SEED_09 )
				return 9;
			#elif defined( SEED_10 )
				return 10;
			#elif defined( SEED_11 )
				return 11;
			#elif defined( SEED_12 )
				return 12;
			#elif defined( SEED_13 )
				return 13;
			#elif defined( SEED_14 )
				return 14;
			#elif defined( SEED_15 )
				return 15;
			#elif defined( SEED_16 )
				return 16;
			#elif defined( SEED_17 )
				return 17;
			#elif defined( SEED_18 )
				return 18;
			#elif defined( SEED_19 )
				return 19;
			#elif defined( SEED_20 )
				return 20;
			#endif
		#endif

		return 546546;
	}
	uint GetUserDataUint( uint InstanceIndex )
	{
		return uint( Data[ InstanceIndex + PDXMESH_USER_DATA_OFFSET + 0 ].x );
	}
	float GetUserDataFloat( uint InstanceIndex )
	{
		return uint( Data[ InstanceIndex + PDXMESH_USER_DATA_OFFSET + 0 ].x );
	}
	int GetUserDataCountryIndex( uint InstanceIndex )
	{
		return int( Data[ InstanceIndex + PDXMESH_USER_DATA_OFFSET + 0 ].x );
	}
	float4 GetUserDataBuildingLightColor( uint InstanceIndex )
	{
		return Data[ InstanceIndex + PDXMESH_USER_DATA_OFFSET + 0 ];
	}
	float GetUserDataPrettyValue( uint InstanceIndex )
	{
		return Data[ InstanceIndex + PDXMESH_USER_DATA_OFFSET + 1 ].x;
	}
	float GetUserDataRandomValueCity( uint InstanceIndex )
	{
		return Data[ InstanceIndex + PDXMESH_USER_DATA_OFFSET + 1 ].y;
	}
	float GetUserDataShouldLightActivate( uint InstanceIndex )
	{
		return Data[ InstanceIndex + PDXMESH_USER_DATA_OFFSET + 1 ].z;
	}

	SStandardMeshUserData GetStandardMeshUserData( uint InstanceIndex )
	{
		SStandardMeshUserData UserData;
		UserData._CountryIndex = Data[ InstanceIndex + PDXMESH_USER_DATA_OFFSET + 0 ].x;
		UserData._RandomValue = Data[ InstanceIndex + PDXMESH_USER_DATA_OFFSET + 0 ].y;
		UserData._PowerBlocIndex = Data[ InstanceIndex + PDXMESH_USER_DATA_OFFSET + 0 ].z;
		return UserData;
	}

	SBuildingMeshUserdata GetBuildingMeshUserData( uint InstanceIndex )
	{
		SBuildingMeshUserdata UserData;
		UserData._LightColor = Data[ InstanceIndex + PDXMESH_USER_DATA_OFFSET + 0 ];

		UserData._CountryIndex = Data[ InstanceIndex + PDXMESH_USER_DATA_OFFSET + 1 ].x;
		UserData._RandomValue = Data[ InstanceIndex + PDXMESH_USER_DATA_OFFSET + 1 ].y;
		UserData._SolValue = Data[ InstanceIndex + PDXMESH_USER_DATA_OFFSET + 1 ].z;
		UserData._ShouldLightActivate = Data[ InstanceIndex + PDXMESH_USER_DATA_OFFSET + 1 ].w;

		UserData._HasCompanyTexture = Data[ InstanceIndex + PDXMESH_USER_DATA_OFFSET + 2 ].x;
		UserData._PowerBlocIndex = Data[ InstanceIndex + PDXMESH_USER_DATA_OFFSET + 2 ].y;

		return UserData;
	}


	SShipMeshUserData GetShipMeshUserData( uint InstanceIndex )
	{
		SShipMeshUserData UserData;
		UserData._CountryIndex = Data[ InstanceIndex + PDXMESH_USER_DATA_OFFSET + 0 ].x;
		UserData._Damage = Data[ InstanceIndex + PDXMESH_USER_DATA_OFFSET + 0 ].y;
		UserData._DecalPosition01 = Data[ InstanceIndex + PDXMESH_USER_DATA_OFFSET + 1 ];
		UserData._DecalPosition02 = Data[ InstanceIndex + PDXMESH_USER_DATA_OFFSET + 2 ];
		UserData._DecalPosition03 = Data[ InstanceIndex + PDXMESH_USER_DATA_OFFSET + 3 ];
		UserData._DecalPosition04 = Data[ InstanceIndex + PDXMESH_USER_DATA_OFFSET + 4 ];
		return UserData;
	}
]]

VertexShader =
{
	Code
	[[
		WaveAnimationSettings GetWaveAnimationSettingsDefault()
		{
			WaveAnimationSettings WaveAnimSettings;
			WaveAnimSettings.LargeWaveFrequency = 3.14f;
			WaveAnimSettings.SmallWaveFrequency = 9.0f;
			WaveAnimSettings.WaveLenghtPow = 1.0f;
			WaveAnimSettings.WaveLengthInvScale = 7.0f;
			WaveAnimSettings.WaveScale = 0.2f;
			WaveAnimSettings.AnimationSpeed = 0.5f;

			return WaveAnimSettings;
		}
		WaveAnimationSettings GetWaveAnimationSettingsBuilding()
		{
			WaveAnimationSettings WaveAnimSettings;
			WaveAnimSettings.LargeWaveFrequency = 2.0f;
			WaveAnimSettings.SmallWaveFrequency = 7.0f;
			WaveAnimSettings.WaveLenghtPow = 1.0f;
			WaveAnimSettings.WaveLengthInvScale = 5.0f;
			WaveAnimSettings.WaveScale = 0.08f;
			WaveAnimSettings.AnimationSpeed = 0.5f;

			return WaveAnimSettings;
		}

		void CalculateSineAnimation( float2 UV, inout float3 Position, inout float3 Normal, inout float4 Tangent, float Seed )
		{
			#if defined( FLAGWAVE_SETTINGS_BUILDING )
			WaveAnimationSettings AnimSettings = GetWaveAnimationSettingsBuilding();
			#else
				WaveAnimationSettings AnimSettings = GetWaveAnimationSettingsDefault();
			#endif

			float AnimSeed = UV.x;
			float RandomOffset = CalcRandom( Seed + GetSeed() );
			float Time = ( GlobalTime + RandomOffset ) * AnimSettings.AnimationSpeed;

			float LargeWave = sin( Time * AnimSettings.LargeWaveFrequency );
			float SmallWaveV = Time * AnimSettings.SmallWaveFrequency - pow( AnimSeed, AnimSettings.WaveLenghtPow ) * AnimSettings.WaveLengthInvScale;
			float SmallWaveD = -( AnimSettings.WaveLenghtPow * pow( AnimSeed, AnimSettings.WaveLenghtPow ) * AnimSettings.WaveLengthInvScale );
			float SmallWave = sin( SmallWaveV );
			float CombinedWave = SmallWave + LargeWave;

			float Wave = AnimSettings.WaveScale * AnimSeed * CombinedWave;
			float Derivative = AnimSettings.WaveScale * ( LargeWave + SmallWave + cos( SmallWaveV ) * SmallWaveD );
			float3 AnimationDir = cross( Tangent.xyz, float3( 0.0, 1.0, 0.0 ) );

			Position += AnimationDir * Wave;

			float2 WaveTangent = normalize( float2( 1.0f, Derivative ) );
			float3 WaveNormal = normalize( float3( WaveTangent.y, 0.0f, -WaveTangent.x ));
			Normal = normalize( WaveNormal ); // wave normal strength
		}

		float3 WindTransform( float3 Position, float4x4 WorldMatrix )
		{
			float3 WorldSpacePos = mul( WorldMatrix, float4( Position, 1.0f ) ).xyz;
			float2 MapCoords = float2( WorldSpacePos.x / MapSize.x, 1.0 - WorldSpacePos.z / MapSize.y );

			float3 FlowMap = PdxTex2DLod0( FlowMapTexture, MapCoords ).rgb;
			float3 FlowDir = FlowMap.xyz * 2.0 - 1.0;
			FlowDir = FlowDir / ( length( FlowDir ) + 0.000001 ); // Intel did not like normalize()

			float WindMap = PdxTex2DLod0( WindMapTree, MapCoords ).r;

			// HarvestCondition mask
			HarvestConditionData ConditionData;
			float2 HarvestCoords = WorldSpacePos.xz * _WorldSpaceToTerrain0To1;
			SampleHarvestConditionMask( HarvestCoords, ConditionData );
			float WindMultiplier = lerp( 1.0, ExtremeWindSwaySpeed, ConditionData._ExtremeWinds );
			float SwayMultiplier = lerp( 1.0, ExtremeWindSwayScale, ConditionData._ExtremeWinds );

			float WorldX = GetMatrixData( WorldMatrix, 0, 3 );
			float WorldY = GetMatrixData( WorldMatrix, 2, 3 );
			float Noise = CalcNoise( GlobalTime * TreeSwayLoopSpeed + TreeSwayWindStrengthSpatialModifier * float2( WorldX, WorldY ) );
			float WindSpeed = Noise * Noise;
			float Phase = GlobalTime * TreeSwaySpeed * WindMultiplier + TreeSwayWindClusterSizeModifier * ( WorldX + WorldY );
			float3 Offset = normalize( float3( FlowDir.x, 0.0f, FlowDir.z ) );
			Offset = mul( Offset, CastTo3x3( WorldMatrix ) );
			float HeightFactor = saturate( Position.y * TreeHeightImpactOnSway );
			HeightFactor *= HeightFactor;

			float wave = sin( Phase ) + 0.5f;
			Position += TreeSwayScale * SwayMultiplier * WindMap * HeightFactor * wave * Offset * WindSpeed;

			return Position;
		}

		float3 WindTransformBush( float3 Position, float4x4 WorldMatrix )
		{
			float3 WorldSpacePos = mul( WorldMatrix, float4( Position, 1.0f ) ).xyz;
			float2 MapCoords = float2( WorldSpacePos.x / MapSize.x, 1.0 - WorldSpacePos.z / MapSize.y );

			float3 FlowMap = PdxTex2DLod0( FlowMapTexture, MapCoords ).rgb;
			float3 FlowDir = FlowMap.xyz * 2.0 - 1.0;
			FlowDir = FlowDir / ( length( FlowDir ) + 0.000001 ); // Intel did not like normalize()

			float WindMap = PdxTex2DLod0( WindMapTree, MapCoords ).r;

			// HarvestCondition mask
			HarvestConditionData ConditionData;
			float2 HarvestCoords = WorldSpacePos.xz * _WorldSpaceToTerrain0To1;
			SampleHarvestConditionMask( HarvestCoords, ConditionData );
			float WindMultiplier = lerp( 1.0, ExtremeWindSwaySpeed, ConditionData._ExtremeWinds );
			float SwayMultiplier = lerp( 1.0, ExtremeWindSwayScale, ConditionData._ExtremeWinds );

			float WorldX = GetMatrixData( WorldMatrix, 0, 3 );
			float WorldY = GetMatrixData( WorldMatrix, 2, 3 );
			float Noise = CalcNoise( GlobalTime * TreeSwayLoopSpeed + TreeSwayWindStrengthSpatialModifier * float2( WorldX, WorldY ) );
			float WindSpeed = Noise * Noise;
			float Phase = GlobalTime * TreeSwaySpeed * WindMultiplier + TreeSwayWindClusterSizeModifier * ( WorldX + WorldY );
			float3 Offset = normalize( float3( FlowDir.x, 0.0f, FlowDir.z ) );
			Offset = mul( Offset, CastTo3x3( WorldMatrix ) );
			float HeightFactor = saturate( Position.y * TreeHeightImpactOnSway * BUSH_TREE_HEIGHT_IMPACT );
			HeightFactor *= HeightFactor;

			float wave = sin( Phase ) + 0.5f;
			Position += TreeSwayScale * BUSH_TREE_SWAY_SCALE * SwayMultiplier * WindMap * HeightFactor * wave * Offset * WindSpeed;

			return Position;
		}

		float3 WindTransformMedium( float3 Position, float4x4 WorldMatrix )
		{
			float3 WorldSpacePos = mul( WorldMatrix, float4( Position, 1.0f ) ).xyz;
			float2 MapCoords = float2( WorldSpacePos.x / MapSize.x, 1.0 - WorldSpacePos.z / MapSize.y );

			float3 FlowMap = PdxTex2DLod0( FlowMapTexture, MapCoords ).rgb;
			float3 FlowDir = FlowMap.xyz * 2.0 - 1.0;
			FlowDir = FlowDir / ( length( FlowDir ) + 0.000001 ); // Intel did not like normalize()

			float WindMap = PdxTex2DLod0( WindMapTree, MapCoords ).r;

			// HarvestCondition mask
			HarvestConditionData ConditionData;
			float2 HarvestCoords = WorldSpacePos.xz * _WorldSpaceToTerrain0To1;
			SampleHarvestConditionMask( HarvestCoords, ConditionData );
			float WindMultiplier = lerp( 1.0, ExtremeWindSwaySpeed, ConditionData._ExtremeWinds );
			float SwayMultiplier = lerp( 1.0, ExtremeWindSwayScale, ConditionData._ExtremeWinds );

			float WorldX = GetMatrixData( WorldMatrix, 0, 3 );
			float WorldY = GetMatrixData( WorldMatrix, 2, 3 );
			float Noise = CalcNoise( GlobalTime * TreeSwayLoopSpeed + TreeSwayWindStrengthSpatialModifier * float2( WorldX, WorldY ) );
			float WindSpeed = Noise * Noise;
			float Phase = GlobalTime * TreeSwaySpeed * MEDIUM_TREE_SWAY_SPEED * WindMultiplier + TreeSwayWindClusterSizeModifier * ( WorldX + WorldY );
			float3 Offset = normalize( float3( FlowDir.x, 0.0f, FlowDir.z ) );
			Offset = mul( Offset, CastTo3x3( WorldMatrix ) );
			float HeightFactor = saturate( Position.y * TreeHeightImpactOnSway * MEDIUM_TREE_HEIGHT_IMPACT );
			HeightFactor *= HeightFactor;

			float wave = sin( Phase ) + 0.5f;
			Position += TreeSwayScale * MEDIUM_TREE_SWAY_SCALE * SwayMultiplier * WindMap * HeightFactor * wave * Offset * WindSpeed;

			return Position;
		}

		float3 WindTransformTall( float3 Position, float4x4 WorldMatrix )
		{
			float3 WorldSpacePos = mul( WorldMatrix, float4( Position, 1.0f ) ).xyz;
			float2 MapCoords = float2( WorldSpacePos.x / MapSize.x, 1.0 - WorldSpacePos.z / MapSize.y );

			float3 FlowMap = PdxTex2DLod0( FlowMapTexture, MapCoords ).rgb;
			float3 FlowDir = FlowMap.xyz * 2.0 - 1.0;
			FlowDir = FlowDir / ( length( FlowDir ) + 0.000001 ); // Intel did not like normalize()

			float WindMap = PdxTex2DLod0( WindMapTree, MapCoords ).r;

			// HarvestCondition mask
			HarvestConditionData ConditionData;
			float2 HarvestCoords = WorldSpacePos.xz * _WorldSpaceToTerrain0To1;
			SampleHarvestConditionMask( HarvestCoords, ConditionData );
			float WindMultiplier = lerp( 1.0, ExtremeWindSwaySpeed, ConditionData._ExtremeWinds );
			float SwayMultiplier = lerp( 1.0, ExtremeWindSwayScale, ConditionData._ExtremeWinds );

			float WorldX = GetMatrixData( WorldMatrix, 0, 3 );
			float WorldY = GetMatrixData( WorldMatrix, 2, 3 );
			float Noise = CalcNoise( GlobalTime * TreeSwayLoopSpeed + TreeSwayWindStrengthSpatialModifier * float2( WorldX, WorldY ) );
			float WindSpeed = Noise * Noise;
			float Phase = GlobalTime * TreeSwaySpeed * TALL_TREE_SWAY_SPEED * WindMultiplier + TreeSwayWindClusterSizeModifier * ( WorldX + WorldY );
			float3 Offset = normalize( float3( FlowDir.x, 0.0f, FlowDir.z ) );
			Offset = mul( Offset, CastTo3x3( WorldMatrix ) );
			float HeightFactor = saturate( Position.y * TreeHeightImpactOnSway * TALL_TREE_HEIGHT_IMPACT );
			HeightFactor *= HeightFactor;

			float wave = sin( Phase ) + 0.5f;
			Position += TreeSwayScale * TALL_TREE_SWAY_SCALE * SwayMultiplier * WindMap * HeightFactor * wave * Offset * WindSpeed;

			return Position;
		}

		float3 SnapToWaterLevel( float3 PositionY, float4x4 WorldMatrix )
		{
			float3 WorldSpacePos = mul( WorldMatrix, float4( float3( 0.0f, 0.0f, 0.0f ), 1.0f ) ).xyz;

			float Height = GetHeight( WorldSpacePos.xz );
			PositionY += ( _WaterHeight - WorldSpacePos.y );

			return PositionY;
		}

	]]
}

PixelShader =
{
	Code
	[[
		void DebugRandomSeed( inout float3 Color, float Seed, float Variance = 1.0 )
		{
			Color = float3( 1.0, 0.0, 0.0 );
			float3 HSV_ = RGBtoHSV( Color );
			HSV_.x += float( Seed * Variance );
			Color = HSVtoRGB( HSV_ );
		}

		void AddBacklight( inout float3 Base, float3 AddColor, float3 Normal, float3 Light, float Intensity = 0.5 )
		{
				float3 InverseLight = saturate( 1.0 - dot( Normal, Light ) );
				Base = saturate( ( Base + ( AddColor * Intensity * InverseLight ) ) );
		}

		void ApplyStandardOfLiving( inout float3 Color, float2 Uv, float SolValue, float3 WorldSpacePos, float3 Normal )
		{
			float SolHigh = _SolDebugHigh;
			float SolLow = _SolDebugLow;

			if ( SolValue < 0.5 )
			{
				SolLow += SolValue * 2.0;
			}
			else
			{
				SolHigh += ( SolValue - 0.5 ) * 2.0;
			}

			SolHigh = saturate( SolHigh );
			SolLow = saturate( SolLow );

			float LocalHeight = WorldSpacePos.y - GetHeight( WorldSpacePos.xz );
			float TintAngleModifier = saturate( 1.0 - dot( Normal, float3( 0.0, 1.0, 0.0 ) ) );	// Removes tint from angles facing upwards
			float TintTopBlend = saturate( RemapClamped( LocalHeight - _SolHighTintHeight + _SolHighTintContrast, 0.0, _SolHighTintContrast, 0.0, 1.0 ) );
			float TintBottomBlend = ( 1.0 - RemapClamped( LocalHeight - _SolLowTintHeight, 0.0, _SolLowTintContrast, 0.0, 1.0 ) );

			float3 SolLowColor = PdxTex2D( SolLowTexture, Uv ).rgb;

			float3 HSV_ = RGBtoHSV( Color );
			HSV_.x *= _SolHighHue; 			// Hue
			HSV_.y *= _SolHighSaturation; 	// Saturation
			HSV_.z *= _SolHighValue; 		// Value
			float3 SaturatedColor = saturate( HSVtoRGB( HSV_ ) );

			Color = lerp( Color, SaturatedColor, TintTopBlend * SolHigh );
			Color = lerp( Color, Overlay( Color, SolLowColor ), TintBottomBlend * TintAngleModifier * SolLow );
		}

		float2 InteriorIntersect( in float3 RayOrigin, in float3 RayDirection, in float3 Axis, in float PlaneSpacing, in float PositiveId, in float NegativeId )
		{
			float RayDotAxis = dot( RayDirection, Axis );
			float OriginDotAxis = dot( RayOrigin, Axis );
			float PlaneIndex = ceil( OriginDotAxis / PlaneSpacing );

			if ( RayDotAxis > 0.0 )
			{
				float PlaneHeight = PlaneIndex * PlaneSpacing;
				float T = ( PlaneHeight - OriginDotAxis ) / RayDotAxis;
				return float2( T, PositiveId );
			}
			else
			{
				float PlaneHeight = ( PlaneIndex - 1.0 ) * PlaneSpacing;
				float T = ( PlaneHeight - OriginDotAxis ) / RayDotAxis;
				return float2( T, NegativeId );
			}
		}

		float2 InteriorNearest( in float2 Candidate1, in float2 Candidate2, in float2 Candidate3 )
		{
			if ( Candidate1.x < Candidate2.x )
			{
				return Candidate1.x < Candidate3.x ? Candidate1 : Candidate3;
			}
			else
			{
				return Candidate2.x < Candidate3.x ? Candidate2 : Candidate3;
			}
		}

		float3 RenderInterior( in float2 HitInfo, in float3 RayOrigin, in float3 RayDirection, in float3 RoomSize, PdxTextureSampler2D Texture )
		{
			float T = HitInfo.x;
			float FaceId = HitInfo.y;

			float3 HitPosition = RayOrigin + T * RayDirection;

			// 2x2 atlas layout (left to right, top to bottom):
			// (0,0) Wall  | (1,0) Floor
			// (0,1) Ceiling | (1,1) Back wall
			float2 AtlasScale = float2( 0.5, 0.5 );
			float2 WallOffset = float2( 0.0, 0.0 );
			float2 FloorOffset = float2( 0.5, 0.0 );
			float2 CeilingOffset = float2( 0.0, 0.5 );
			float2 BackWallOffset = float2( 0.5, 0.5 );

			float2 Uv;

			// Floor (Up positive)
			if ( FaceId > 0.9 && FaceId < 1.1 )
			{
				Uv = frac( float2( HitPosition.x, -HitPosition.z ) );
				Uv.y = 1.0 - Uv.y;
				Uv = Uv * AtlasScale + FloorOffset;
				return PdxTex2D( Texture, Uv ).rgb;
			}
			// Ceiling (Up negative)
			else if ( FaceId > 1.9 && FaceId < 2.1 )
			{
				Uv = frac( HitPosition.xz );
				Uv.y = 1.0 - Uv.y;
				Uv = Uv * AtlasScale + CeilingOffset;
				return PdxTex2D( Texture, Uv ).rgb;
			}
			// Right wall (Right positive)
			else if ( FaceId > 2.9 && FaceId < 3.1 )
			{
				Uv = frac( float2( -HitPosition.z, HitPosition.y ) );
				Uv = Uv * AtlasScale + WallOffset;
				return PdxTex2D( Texture, Uv ).rgb;
			}
			// Left wall (Right negative)
			else if ( FaceId > 3.9 && FaceId < 4.1 )
			{
				Uv = frac( HitPosition.zy );
				Uv.x = 1.0 - Uv.x;
				Uv = Uv * AtlasScale + WallOffset;
				return PdxTex2D( Texture, Uv ).rgb;
			}
			// Back wall (Forward positive)
			else if ( FaceId > 4.9 && FaceId < 5.1 )
			{
				Uv = frac( HitPosition.xy ) * AtlasScale + BackWallOffset;
				return PdxTex2D( Texture, Uv ).rgb;
			}
			// Front wall (Forward negative)
			else if ( FaceId > 5.9 && FaceId < 6.1 )
			{
				Uv = frac( HitPosition.xy ) * AtlasScale + BackWallOffset;
				return PdxTex2D( Texture, Uv ).rgb;
			}

			return float3( 0.0, 0.0, 0.0 );
		}

	]]
}
