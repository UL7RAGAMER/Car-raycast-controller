shader_type spatial;

uniform float arc_radius = 5.0;      // Radius of the arc (larger = gentler curve)
uniform float arc_strength = 1.0;    // 0.0 = flat, 1.0 = full arc
uniform bool bend_x_axis = true;     // If true, bend along X (in XZ plane)

void vertex() {
    if (arc_strength == 0.0 || arc_radius == 0.0) {
        ; // No bending
    }

    float x = VERTEX.x;
    float z = VERTEX.z;
    float angle;

    if (bend_x_axis) {
        angle = x / arc_radius * arc_strength;
        VERTEX.x = sin(angle) * arc_radius;
        VERTEX.z = arc_radius - cos(angle) * arc_radius;
    } else {
        angle = z / arc_radius * arc_strength;
        VERTEX.z = sin(angle) * arc_radius;
        VERTEX.x = arc_radius - cos(angle) * arc_radius;
    }

    // Normals not rotated here — use NORMAL rotation only if lighting looks bad
}
