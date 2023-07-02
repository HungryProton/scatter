#[compute]
#version 450

// Invocations in the (x, y, z) dimension
layout(local_size_x = 2, local_size_y = 1, local_size_z = 1) in;

// A binding to the input buffer we create in our script
layout(set = 0, binding = 0, std430) readonly buffer MyDataBuffer {
    vec4 data[];
}
buffer_in;

// A binding to the output buffer we create in our script
layout(set = 0, binding = 1, std430) buffer MyDataBuffer2 {
    vec4 data[];
}
buffer_out;

// The code we want to execute in each invocation
void main() {
    // gl_GlobalInvocationID.x uniquely identifies this invocation across all work groups
    int last_element_index = buffer_in.data.length();
    uint index = gl_GlobalInvocationID.x;
    vec3 infvec = vec3(999999, 999999, 999999);
    vec3 closest = infvec;
    vec3 origin = buffer_in.data[gl_GlobalInvocationID.x].xyz;

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

    //lets hope buffer is cached
    //buffer_in.data[index] = closest - origin;
    //buffer_out.data[index] = buffer_in.data[last_element_index - index];
    buffer_out.data[index] = buffer_in.data[index];
}
