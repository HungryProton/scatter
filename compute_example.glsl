#[compute]
#version 450

// Invocations in the (x, y, z) dimension
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

// A binding to the input buffer we create in our script
layout(set = 0, binding = 0, std430) readonly buffer MyDataBuffer {
    vec4 data[];
}
buffer_in;

// A binding to the output buffer we create in our script
layout(set = 0, binding = 1, std430) restrict buffer MyDataBuffer2 {
    vec4 data[];
}
buffer_out;

// The code we want to execute in each invocation
void main() {
    // gl_GlobalInvocationID.x uniquely identifies this invocation across all work groups
    int last_element_index = buffer_in.data.length();
    //uint index = gl_GlobalInvocationID.x + gl_GlobalInvocationID.y * 8;
    uint index = gl_WorkGroupID.x * 64 + gl_LocalInvocationIndex;

    vec3 infvec = vec3(1, 1, 1) * 999999;
    vec3 closest = infvec;
    vec3 origin = buffer_in.data[index].xyz;

    for(int i = 0; i <= last_element_index; i++){
        vec3 newvec = buffer_in.data[i].xyz;
        //newvec += infvec * float(i == index); // disregard itself by making it very far away
        if (i == index) continue;

        float olddist = length(closest - origin);
        float newdist = length(newvec - origin);

        //closest = (newdist < olddist) ? newvec : closest;
        if (newdist < olddist)
        {
            closest = newvec;
        }
    }
    buffer_out.data[index] = vec4(origin - closest, 0);
    //buffer_out.data[index] = vec4(vec3(index), 0);
}
