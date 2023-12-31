Shader "Custom/ShieldShader"
{
    Properties
    {
		//Allows the RGBA of the shader to be edited in the Unity Editor
        _Colour("Colour", COLOR) = (0,0,0,0)

        //Defines the hexagon texture variable
        _PulseTex("Hex Pulse Texture", 2D) = "white" {}

        //Controls intensity of the hexagon colour from the Unity Editor
        _PulseIntensity("Hex Pulse Intensity", float) = 3.0

        //Controls speed of the hexagon fading animation from the Unity Editor
        _PulseTimeScale("Hex Pulse Time Scale", float) = 2.0

        //Scales hexagon's animation from within the Unity Editor (this affects speed of animation)
        _PulsePosScale("Hex Pulse Position Scale", float) = 50.0

        //Emphasises the appearance of hexagons in the animated pulse, as hexagons fade in and out at different times, rather than in unison
        _PulseTexOffsetScale("Hex Pulse Texture Offset Scale", float) = 1.5

        //Defines the texture that moves from the centre of the shield to the edges in a diamond shape
        //Highlights the edges of the hexagons
        _HexEdgeTex("Hex Edge Texture", 2D) = "white" {}

        //Defines the intensity of the hex edge texture
        _HexEdgeIntensity("Hex Edge Intensity", float) = 2.0

        //Defines the colour of hex edge texture from within the Unity Editor
        _HexEdgeColour("Hex Edge Colour", COLOR) = (1,0,0,0)

        //Controls the speed of the animation of the hex edge texture
        _HexEdgeTimeScale("Hex Edge Time Scale", float) = 2.0

        //Controls thickness of the animated diamond shape
        _HexEdgeWidthModifier("Hex Edge Width Modifier", Range(0, 1)) = 0.8

        //Adjust the distance between waves of diamond animation
        _HexEdgePosScale("Hex Edge Position Scale", float) = 80.0

        //Define shield outline texture from Unity Editor
        _OutlineTex("Outline Texture", 2D) = "white" {}

        //Define shield outline colour intensity from Unity Editor
        _OutlineIntensity("Outline Intensity", float) = 10.0

        //Define thickness of the shield outline texture from Unity Editor
        _OutlineExponent("Outline Falloff Exponent", float) = 6.0

    }  

	SubShader
	{
        //Disable backface culling
        Cull Off

        //Define render type, render queue position, and blend mode, to enable transparency
        Tags {"RenderType" = "Transparent" "Queue" = "Transparent"}
        //Define blend mode as an additive blend
        Blend SrcAlpha One

		Pass
		{
			HLSLPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
            
			struct appdata
			{
				float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                //Access the vertices' positions
                float4 vertexObjPos : TEXCOORD1;
                float2 screenPos : TEXCOORD2;
                float depth : TEXCOORD3;
			};
            
            //DECLARE VARIABLES
            float4 _Colour;

            //Declare pulse texture variables
            sampler2D _PulseTex;
            //_ST float 4 variables is used to store tiling and offset values
            float4 _PulseTex_ST;
            float _PulseIntensity;
            float _PulseTimeScale;
            float _PulsePosScale;
            //Represents the horizontal distance from the centre
            float horizontalDist; 
            float _PulseTexOffsetScale;

            //Declare moving edge texture variables
            sampler2D _HexEdgeTex;
            float4 _HexEdgeTex_ST;
            float _HexEdgeIntensity;
            float4 _HexEdgeColour;
            float _HexEdgeTimeScale;
            float _HexEdgeWidthModifier;
            float _HexEdgePosScale;

            //Declare shield outline texture variables
            sampler2D _OutlineTex;
            float4 _OutlineTex_ST;
            float _OutlineIntensity;
            float _OutlineExponent;


			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _PulseTex);
                o.vertexObjPos = v.vertex;
                //convert clip position to screen position
                o.screenPos = ComputeScreenPos(o.vertex);
                o.depth = -mul(UNITY_MATRIX_MV, v.vertex).z * _ProjectionParams.w;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
                //Positions from centre of SV_Target
                float verticalDist = abs(i.vertexObjPos.z);
                float horizontalDist = abs(i.vertexObjPos.x);

                //PULSE TEXTURE
                fixed4 pulseTex = tex2D(_PulseTex, i.uv);
                //controls colour and placement of colour of the hexagons on the shield
                fixed4 pulseTerm = pulseTex * _Colour * _PulseIntensity;
                //animates the hexagons on the shield to fade in and out
                pulseTerm *= abs(sin(_Time.y * _PulseTimeScale - horizontalDist * _PulsePosScale + pulseTex.r * _PulseTexOffsetScale));

                //HEXAGON EDGE TEXTURE
                fixed4 hexEdgeTex = tex2D(_HexEdgeTex, i.uv);
                //controls colour and placement of colour of the edges of the hexagons on the shield
                fixed4 hexEdgeTerm = hexEdgeTex * _HexEdgeColour * _HexEdgeIntensity;
                //create animated diamond shape of the moving edges of the hexagons
                hexEdgeTerm *= max(sin((horizontalDist + verticalDist) * _HexEdgePosScale - _Time.y * _HexEdgeTimeScale) - _HexEdgeWidthModifier, 0.0f);
                //normalise the result to keep it within 0 - 1 range
                hexEdgeTerm *= 1 / (1 - _HexEdgeWidthModifier);

                //SHIELD OUTLINE TEXTURE
                fixed4 outlineTex = tex2D(_OutlineTex, i.uv);
                //creates a transparency gradient in the outline
                fixed4 outlineTerm = pow(outlineTex.a, _OutlineExponent);
                //controls colour of the outline
                outlineTerm *= _Colour * _OutlineIntensity;

				//OUTPUT
				return fixed4(_Colour.rgb + pulseTerm.rgb + hexEdgeTerm.rgb + outlineTerm, _Colour.a);
			}

			ENDHLSL
		}
	}
}