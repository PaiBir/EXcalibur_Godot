shader_type sky;

uniform float star_angular_size = 0.5;
uniform float starEdge1 = 125.0;
uniform float starEdge2 = 360;
uniform vec3 colors[3] : source_color;
uniform sampler2D Cubemap_Stars[6] : repeat_disable;
uniform sampler2D Cubemap_Nebula[6] : repeat_disable;

float localMax (vec3 vector){
	return max(max(vector.x, vector.y), vector.z);
}

vec2 toCube (vec3 trucoord) {
	return 0.5+(trucoord.xy/trucoord.z)*0.5;
}

void sky() {
	if(AT_CUBEMAP_PASS) {
		COLOR = vec3(0.0,0.0,0.0);
	} else {
		//Fancy Sky
		//Establish Star
		//For each direction: Get the position of the point, find the angle to that point, add half a pi, divide by half a radian-to-degrees
		//This gives us a range from 0 degrees (-dir) to 360 degrees (+dir), where an angular diameter of 360 encompasses the sky, 180 covers half the sky, and 0 does not appear in the sky
		vec3 dir = vec3((asin(EYEDIR.x) + (PI / 2.0) ) / (PI / 360.0),(asin(EYEDIR.y) + (PI / 2.0) ) / (PI / 360.0),(asin(EYEDIR.z) + (PI / 2.0) ) / (PI / 360.0));
		//This morphs the angular diameter to work better visually
		float powerformula = 7.26307*pow(star_angular_size,0.61);
		float effectiveeAngular = (powerformula * min(max(1.0 - ((star_angular_size - starEdge1) / (starEdge2 / starEdge1)), 0.0), 1.0)) + (star_angular_size * min(max((star_angular_size - starEdge1) / (starEdge2 / starEdge1), 0.0), 1.0));
		//This establishes if a point is within our expected angular diameter. 
		bool checkpass = dir.x < effectiveeAngular;
		
		//Color Star
		//The math here should be a reflection of the math above, to establish the star 
		float starcol = (1.0 - (dir.x * (1.0/effectiveeAngular))) * float(checkpass);
		vec3 stcl = mix(colors[2],colors[1],starcol*2.0);
		stcl = mix(stcl, colors[0], starcol) * float(checkpass);
		
		//Corona
		
		//BG
		float Simg = 0.0;
		vec3 Nimg = vec3(0.0);
		if(localMax(abs(EYEDIR)) == abs(EYEDIR).x){
			if(EYEDIR.x < 0.0) {
				Simg = texture(Cubemap_Stars[1],toCube(EYEDIR.zyx) * vec2(1.0,1.0)).x;
				Nimg = texture(Cubemap_Nebula[1],toCube(EYEDIR.zyx) * vec2(1.0,1.0)).xyz;
			} else {
				Simg = texture(Cubemap_Stars[3],vec2(0.0,1.0) + toCube(EYEDIR.zyx) * vec2(1.0,-1.0)).x;
				Nimg = texture(Cubemap_Nebula[3],vec2(0.0,1.0) + toCube(EYEDIR.zyx) * vec2(1.0,-1.0)).xyz;
			}
		}
		if(localMax(abs(EYEDIR)) == abs(EYEDIR).y){
			if(EYEDIR.y < 0.0){
				Simg = texture(Cubemap_Stars[0],vec2(0.0,1.0) + toCube(EYEDIR.zxy) * vec2(1.0,-1.0)).x;
				Nimg = texture(Cubemap_Nebula[0],vec2(0.0,1.0) + toCube(EYEDIR.zxy) * vec2(1.0,-1.0)).xyz;
			} else {
				Simg = texture(Cubemap_Stars[5],vec2(1.0,1.0) + toCube(EYEDIR.zxy) * vec2(-1.0,-1.0)).x;
				Nimg = texture(Cubemap_Nebula[5],vec2(1.0,1.0) + toCube(EYEDIR.zxy) * vec2(-1.0,-1.0)).xyz;
			}
		}
		if(localMax(abs(EYEDIR)) == abs(EYEDIR).z){
			if(EYEDIR.z < 0.0){
				Simg = texture(Cubemap_Stars[2],vec2(1.0,0.0) + toCube(EYEDIR.xyz) * vec2(-1.0,1.0)).x;
				Nimg = texture(Cubemap_Nebula[2],vec2(1.0,0.0) + toCube(EYEDIR.xyz) * vec2(-1.0,1.0)).xyz;
			} else {
				Simg = texture(Cubemap_Stars[4],vec2(1.0,1.0) + toCube(EYEDIR.xyz) * vec2(-1.0,-1.0)).x;
				Nimg = texture(Cubemap_Nebula[4],vec2(1.0,1.0) + toCube(EYEDIR.xyz) * vec2(-1.0,-1.0)).xyz;
			}
		}
		Simg = mix(Simg,0.0,sqrt(max(min((1.0 - ((dir.x) * (1.0/(effectiveeAngular*4.0))))+0.3,1.0),0.0)));
		Simg = mix(Simg,0.0,min(abs(EYEDIR.y)*0.95,1.0));
		Nimg = mix(Nimg,vec3(0.0),max(min((1.0 - ((dir.x) * (1.0/(effectiveeAngular*8.0))))+0.6,1.0),0.0));
		vec3 Nebulatint = vec3(mix(Nimg.x,colors[1].x,Nimg.x),mix(Nimg.y,colors[1].y,Nimg.y),mix(Nimg.z,colors[1].z,Nimg.z));
		Nimg = mix(Nimg,Nebulatint,max(min((1.0 - ((dir.x) * (1.0/(effectiveeAngular*16.0))))+0.12,1.0),0.0));
		Nimg = mix(Nimg,vec3(0.0),abs(EYEDIR.y));
		Nimg = vec3(pow(Nimg.x,2.0),pow(Nimg.y,2.0),pow(Nimg.z,2.0));
		COLOR = mix(mix(vec3(Simg) + (Nimg * 0.015),colors[1],max(min((1.0 - ((dir.x) * (1.0/effectiveeAngular*0.9)))+0.05,1.0),0.0)),stcl,float(checkpass));
	}
}