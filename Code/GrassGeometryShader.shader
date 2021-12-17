Shader "chenjd/Grass" {
	Properties{

		_MainTex("Albedo (RGB)", 2D) = "white" {} //awt up for grass look
		_AlphaTex("Alpha (A)", 2D) = "white" {}//set up for grass color
		_Height("Grass Height", float) = 3 //height
		_Width("Grass Width", range(0, 0.1)) = 0.05 //width 

	}
	SubShader{
		Cull off
			Tags{ "Queue" = "AlphaTest" "RenderType" = "TransparentCutout" "IgnoreProjector" = "True" } //set up


		Pass
		{

			Cull OFF //input for code
			Tags{ "LightMode" = "ForwardBase" }
			AlphaToMask On


			CGPROGRAM

			#include "UnityCG.cginc" //needed for code
			#pragma vertex vert
			#pragma fragment frag
			#pragma geometry geom
			#include "UnityLightingCommon.cginc" //unity input

			#pragma target 4.0

			sampler2D _MainTex; //tsxt for user
			sampler2D _AlphaTex;

			float _Height;//height
			float _Width;//width
			struct v2g
			{
				float4 pos : SV_POSITION; //set up for shader
				float3 norm : NORMAL;
				float2 uv : TEXCOORD0;
			};

			struct g2f
			{
				float4 pos : SV_POSITION; //floats for shader
				float3 norm : NORMAL;
				float2 uv : TEXCOORD0;
			};


			static const float oscillateDelta = 0.05; //movement of grass


		v2g vert(appdata_full v) //update for vectors
		{
			v2g o;
			o.pos = v.vertex;
			o.norm = v.normal;
			o.uv = v.texcoord;

			return o;
		}

		g2f createGSOut() { //vector location
			g2f output;

			output.pos = float4(0, 0, 0, 0);
			output.norm = float3(0, 0, 0);
			output.uv= float2(0, 0);

			return output;
		}


		[maxvertexcount(30)] //count for vectors
		void geom(point v2g points[1], inout TriangleStream<g2f> triStream)
		{
		 
			float4 root = points[0].pos; //points for shader

			const int vertexCount = 12; //final count

			float random = sin(UNITY_HALF_PI * frac(root.x) + UNITY_HALF_PI * frac(root.z)); //vector location for grass


			_Width = _Width + (random / 50);//final width
			_Height = _Height + (random / 5);//final height



			g2f v[vertexCount] = { //final vector location point
				createGSOut(), createGSOut(), createGSOut(), createGSOut(),
				createGSOut(), createGSOut(), createGSOut(), createGSOut(),
				createGSOut(), createGSOut(), createGSOut(), createGSOut()
			};

			
			//处理纹理坐标

			//The inital vertex 
			float currentV = 0;

			//How much does the vertex offsets by
			float offsetV = 1.f /((vertexCount / 2) - 1);

			//处理当前的高度
			//The inital height offset
			float currentHeightOffset = 0;

			//The inital vertex height
			float currentVertexHeight = 0;

			//风的影响系数
			//The wind coefficent 
			float windCoEff = 0;

			//For-loop to control each blades movement with the wind 
			for (int i = 0; i < vertexCount; i++)
			{
				//Add the normals to the vertex array 
				v[i].norm = float3(0, 0, 1);

				//If one of the vertices is equal to the fmod produceed enter the if condition 
				if (fmod(i , 2) == 0)
				{ 
					//The position vertcies array 
					v[i].pos = float4(root.x - _Width , root.y + currentVertexHeight, root.z, 1);
					//The normal vertcies array
					v[i].uv = float2(0, currentV);
				}
				else
				{ 
					//The position vertcies array 
					v[i].pos = float4(root.x + _Width , root.y + currentVertexHeight, root.z, 1);

					//The normal vertcies array
					v[i].uv = float2(1, currentV);

					//The current vertex and the offset vertex added to it 
					currentV += offsetV;
					//The current vertex height which is a multiplication of the current vertex and height 
					currentVertexHeight = currentV * _Height;
				}


				if(root.x >= 32){
					if(root.z >= 32){			//x,z >= 32 - Q1
						float2 wind = float2(sin(_Time.x * UNITY_PI * 10), sin(_Time.x * UNITY_PI * 10)); 	//control initial wind direction (-x, +z)
						wind.x += (sin(_Time.x + root.x / 25) + sin((_Time.x + root.x / 15) + 50)) * 0.5;	//control x axis of wind control
						wind.y += cos(_Time.x + root.z / 80);												//control y axis of wind control (z-axis on plane)
						wind *= lerp(0.7, 1.0, 1.0 - random); 												//modify all wind directions with random value

						float oscillationStrength = 2.5f;													//control strength of oscillation
						float sinSkewCoeff = random;														//control skewing of sin functions
						float lerpCoeff = (sin(oscillationStrength * _Time.x + sinSkewCoeff) + 1.0) / 2;	//set control for skewing of lerp functions
						float2 leftWindBound = wind+5;														//set left bound of wind control
						float2 rightWindBound = wind+2;														//set right bound of wind control

						wind = lerp(leftWindBound, rightWindBound, lerpCoeff);								//control wind (between left and right bounds)
						float randomAngle = lerp(-UNITY_PI, UNITY_PI, random);								//choose a randomAngle between blade parts
						float randomMagnitude = lerp(0, 1., random);										//choose the magnititude of wind
						float2 randomWindDir = float2(sin(randomAngle), cos(randomAngle));					//choose wind based on random Angle
						wind += -randomWindDir * randomMagnitude;											//modify wind value with magnitude and direction (vector)
						float windForce = length(wind);														//set force of wind based on the length of wind

						v[i].pos.xz += wind.xy * windCoEff;													//change position of blade pieces based on changes in wind
						v[i].pos.y -= windForce * windCoEff * 0.8;											//change y position of blade pieces based on changes in wind

						v[i].pos = UnityObjectToClipPos(v[i].pos);											//tell Unity to perform animation

						if (fmod(i, 2) == 1) {																//if condition to change windCoEff
							windCoEff += offsetV;															//change windCoeff
						}

					}else{ 						//x >=32, z <32 - Q4
						float2 wind = float2(sin(_Time.x * UNITY_PI * 10), sin(_Time.x * UNITY_PI * -10)); 	//control initial wind direction (-x, +z)
						wind.x += (sin(_Time.x + root.x / 25) + sin((_Time.x + root.x / 15) + 50)) * 0.5;	//control x axis of wind control
						wind.y += cos(_Time.x + root.z / 80);												//control y axis of wind control (z-axis on plane)
						wind *= lerp(0.7, 1.0, 1.0 - random); 												//modify all wind directions with random value

						float oscillationStrength = 2.5f;													//control strength of oscillation
						float sinSkewCoeff = random;														//control skewing of sin functions
						float lerpCoeff = (sin(oscillationStrength * _Time.x + sinSkewCoeff) + 1.0) / 2;	//set control for skewing of lerp functions
						float2 leftWindBound = float2(wind.x+5, wind.y-5);									//set left bound of wind control
						float2 rightWindBound = float2(wind.x+2, wind.y-2);									//set right bound of wind control

						wind = lerp(leftWindBound, rightWindBound, lerpCoeff);								//control wind (between left and right bounds)
						float randomAngle = lerp(-UNITY_PI, UNITY_PI, random);								//choose a randomAngle between blade parts
						float randomMagnitude = lerp(0, 1., random);										//choose the magnititude of wind
						float2 randomWindDir = float2(sin(randomAngle), cos(randomAngle));					//choose wind based on random Angle
						wind += -randomWindDir * randomMagnitude;											//modify wind value with magnitude and direction (vector)
						float windForce = length(wind);														//set force of wind based on the length of wind

						v[i].pos.xz += wind.xy * windCoEff;													//change position of blade pieces based on changes in wind
						v[i].pos.y -= windForce * windCoEff * 0.8;											//change y position of blade pieces based on changes in wind

						v[i].pos = UnityObjectToClipPos(v[i].pos);											//tell Unity to perform animation

						if (fmod(i, 2) == 1) {																//if condition to change windCoEff
							windCoEff += offsetV;															//change windCoeff
						}

					}
				} else if(root.z >= 32){  																//x<32, z>=32 - Q2
					float2 wind = float2(sin(_Time.x * UNITY_PI * -10), sin(_Time.x * UNITY_PI * 10)); 	//control initial wind direction (-x, +z)
					wind.x += (sin(_Time.x + root.x / 25) + sin((_Time.x + root.x / 15) + 50)) * 0.5;	//control x axis of wind control
					wind.y += cos(_Time.x + root.z / 80);												//control y axis of wind control (z-axis on plane)
					wind *= lerp(0.7, 1.0, 1.0 - random); 												//modify all wind directions with random value

					float oscillationStrength = 2.5f;													//control strength of oscillation
					float sinSkewCoeff = random;														//control skewing of sin functions
					float lerpCoeff = (sin(oscillationStrength * _Time.x + sinSkewCoeff) + 1.0) / 2;	//set control for skewing of lerp functions
					float2 leftWindBound = float2(wind.x-5, wind.y+5);									//set left bound of wind control
					float2 rightWindBound = float2(wind.x-2, wind.y+2);									//set right bound of wind control

					wind = lerp(leftWindBound, rightWindBound, lerpCoeff);								//control wind (between left and right bounds)
					float randomAngle = lerp(-UNITY_PI, UNITY_PI, random);								//choose a randomAngle between blade parts
					float randomMagnitude = lerp(0, 1., random);										//choose the magnititude of wind
					float2 randomWindDir = float2(sin(randomAngle), cos(randomAngle));					//choose wind based on random Angle
					wind += -randomWindDir * randomMagnitude;											//modify wind value with magnitude and direction (vector)
					float windForce = length(wind);														//set force of wind based on the length of wind

					v[i].pos.xz += wind.xy * windCoEff;													//change position of blade pieces based on changes in wind
					v[i].pos.y -= windForce * windCoEff * 0.8;											//change y position of blade pieces based on changes in wind

					v[i].pos = UnityObjectToClipPos(v[i].pos);											//tell Unity to perform animation

					if (fmod(i, 2) == 1) {																//if condition to change windCoEff
						windCoEff += offsetV;															//change windCoeff
					}
				}else{ 						//x,z <32 - Q3
					float2 wind = float2(sin(_Time.x * UNITY_PI * -10), sin(_Time.x * UNITY_PI * -10));	//control initial wind direction (-x, +z)
					wind.x += (sin(_Time.x + root.x / 25) + sin((_Time.x + root.x / 15) + 50)) * 0.5;	//control x axis of wind control
					wind.y += cos(_Time.x + root.z / 80);												//control y axis of wind control (z-axis on plane)
					wind *= lerp(0.7, 1.0, 1.0 - random); 												//modify all wind directions with random value

					float oscillationStrength = 2.5f;													//control strength of oscillation
					float sinSkewCoeff = random;														//control skewing of sin functions
					float lerpCoeff = (sin(oscillationStrength * _Time.x + sinSkewCoeff) + 1.0) / 2;	//set control for skewing of lerp functions
					float2 leftWindBound = wind-5;														//set left bound of wind control
					float2 rightWindBound = wind-2;														//set right bound of wind control

					wind = lerp(leftWindBound, rightWindBound, lerpCoeff);								//control wind (between left and right bounds)
					float randomAngle = lerp(-UNITY_PI, UNITY_PI, random);								//choose a randomAngle between blade parts
					float randomMagnitude = lerp(0, 1., random);										//choose the magnititude of wind
					float2 randomWindDir = float2(sin(randomAngle), cos(randomAngle));					//choose wind based on random Angle
					wind += -randomWindDir * randomMagnitude;											//modify wind value with magnitude and direction (vector)
					float windForce = length(wind);														//set force of wind based on the length of wind

					v[i].pos.xz += wind.xy * windCoEff;													//change position of blade pieces based on changes in wind
					v[i].pos.y -= windForce * windCoEff * 0.8;											//change y position of blade pieces based on changes in wind

					v[i].pos = UnityObjectToClipPos(v[i].pos);											//tell Unity to perform animation

					if (fmod(i, 2) == 1) {																//if condition to change windCoEff
						windCoEff += offsetV;															//change windCoeff
					}
				}
				
			}

			for (int p = 0; p < (vertexCount - 2); p++) {												//for loop to update mesh
				triStream.Append(v[p]);																	//update mesh at p
				triStream.Append(v[p + 2]);																//update mesh at p+2
				triStream.Append(v[p + 1]);																//update mesh at p+1
			}
		}


		half4 frag(g2f IN) : COLOR {																				//shader language function to handle color and texture
			fixed4 color = tex2D(_MainTex, IN.uv);																	//color texture
			fixed4 alpha = tex2D(_AlphaTex, IN.uv);																	//shape texture

			half3 worldNormal = UnityObjectToWorldNormal(IN.norm);													//world normal values

			//ads
			fixed3 light;																							//light variable

			//ambient
			fixed3 ambient = ShadeSH9(half4(worldNormal, 1));														//ambient lighting

			//diffuse
			fixed3 diffuseLight = saturate(dot(worldNormal, UnityWorldSpaceLightDir(IN.pos))) * _LightColor0;		//calculate diffusion of light

			//specular Blinn-Phong 
			fixed3 halfVector = normalize(UnityWorldSpaceLightDir(IN.pos) + WorldSpaceViewDir(IN.pos));				//calculate lighting vectors
			fixed3 specularLight = pow(saturate(dot(worldNormal, halfVector)), 15) * _LightColor0;					//calculate vector lighting

			light = ambient + diffuseLight + specularLight;															//take the 3 parts of lighting

			return float4(color.rgb * light, alpha.g);																//set for scene
		}
		ENDCG																										//end shader
	}
	}
}