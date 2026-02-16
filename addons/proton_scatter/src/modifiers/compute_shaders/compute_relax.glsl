#[compute]
#version 450

// Invocations in the (x, y, z) dimension
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

// A binding to the input buffer we create in our script
layout(set = 0, binding = 0, std430) readonly buffer BufferIn {
    vec4 data[];
}
buffer_in;

// A binding to the output buffer we create in our script
layout(set = 0, binding = 1, std430) restrict buffer BufferOut {
    vec4 data[];
}
buffer_out;

// Number of real points in the input buffer (excluding padding).
layout(set = 0, binding = 2, std430) readonly buffer Params {
    int point_count;
}
params;

// The code we want to execute in each invocation
void main() {
    // Unique index for each element
    uint workgroupSize = gl_WorkGroupSize.x * gl_WorkGroupSize.y * gl_WorkGroupSize.z;
    uint index = gl_WorkGroupID.x * workgroupSize + gl_LocalInvocationIndex;
    int point_count = params.point_count;

    // Ignore padded invocations and invalid counts.
    if (point_count <= 0 || index >= uint(point_count)) {
        return;
    }

    vec3 infvec = vec3(1, 1, 1) * 999999; // vector approaching "infinity"
    vec3 closest = infvec; // initialize closest to infinity
    vec3 origin = buffer_in.data[index].xyz;

    for (int i = 0; i < point_count; i++) {
        vec3 newvec = buffer_in.data[i].xyz;

        if (uint(i) == index) continue; // ignore self

        float olddist = length(closest - origin);
        float newdist = length(newvec - origin);
        if (newdist < olddist)
        {
            closest = newvec;
        }
    }
    buffer_out.data[index] = vec4(origin - closest, 0);
}
