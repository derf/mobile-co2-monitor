height = 22;
taster_y = 21;
taster_x = 26;

m3 = 1.55;
nut = [5.4, 2.4, 5.4];
nutbox = [8, 8, 8];
m3_zo = 4;

module battery(top=false) {
    liion = [21.8, 81, height];
    wall1 = [2, 2, 2];
    wall2 = [2, 2, 0];
    if (top) {
        translate(-wall2) cube([liion.x, liion.y, 0] + wall1 + wall2);
    } else {
        difference() {
            translate(-wall1) cube(liion + wall1 + wall2);
            cube(liion);
            translate([liion.x, 0, 0]) cube([wall2.x, 4, height]);
            translate([liion.x, liion.y-15, 0]) cube([wall2.x, 15, height]);
        }
    }
}

module board(top=false) {
    $fn=60;
    pcb = [59, 71, height];
    wall1 = [0, 2, 2];
    wall2 = [2, 2, 0];
    scdwall = [27, 2, 15];
    scdwall_o = [0, pcb.y - scdwall.y - 25, -scdwall.z];
    espwall = [pcb.x, 2, 12];
    espwall_o = [0, pcb.y - espwall.y - 31, -espwall.z];
    disp = [23.5, 13.5, wall1.z];
    disp_o = [32, pcb.y - disp.y - 8, 0];
    disp_wx = [disp.x + 2, 1, 5.5];
    disp_wy = [1, disp.y + 2, 5.5];
    disp_wx1o = [disp_o.x - 1, disp_o.y - 1, -disp_wx.z];
    disp_wx2o = [disp_o.x - 1, disp_o.y + disp.y, -disp_wx.z];
    disp_wy1o = disp_wx1o;
    disp_wy2o = [disp_o.x + disp.x, disp_o.y - 1, -disp_wy.z];
    extra_x = 8;
    extra_y = 8;
    extra_floor = [extra_x, extra_y, wall1.z];
    m3_1_o = [4, -wall1.y, pcb.z-m3_zo];
    m3_2_o = [4, pcb.y + wall2.y + 10, pcb.z-m3_zo];
    if (top) {
        difference() {
            translate(-wall2) cube([pcb.x, pcb.y, 0] + wall1 + wall2 + [wall2.x, 0, 0]);
            for (x = [0:2]) {
                for (y = [0:2]) {
                    translate([5 + 8*x, pcb.y - wall2.y - 2 - 8*y, 0]) cylinder(h=wall2.y, r=2);
                }
            }
            for (x = [0:6]) {
                for (y = [4:7]) {
                    translate([5 + 8*x, pcb.y - wall2.y - 2 - 8*y, 0]) cylinder(h=wall2.y, r=1.5);
                }
            }
            translate(disp_o - [5, 5, 0]) cube(disp + [10, 10, 0]);
            //translate([m3_1_o.x - nut.x/2, 3, 0]) cube(nut);
        }
        for (i = [0:0.1:6]) {
            intersection() {
                union() {
                    translate(disp_wx1o - [i, i, 0]) cube(disp_wx + [2*i, 0, 0]);
                    translate(disp_wx2o - [i, -i, 0]) cube(disp_wx + [2*i, 0, 0]);
                    translate(disp_wy1o - [i, i, 0]) cube(disp_wy + [0, 2*i, 0]);
                    translate(disp_wy2o - [-i, i, 0]) cube(disp_wy + [0, 2*i, 0]);
                }
                translate(disp_o - [i+2, i+2, 6-i]) cube(disp + [2*i+8, 2*i+8, -0.8]);
            }
        }
        translate([0, pcb.y + wall2.y, 0]) cube([extra_x + wall2.x, extra_y + wall1.y, wall1.z]);
        translate(scdwall_o) cube(scdwall);
        translate(espwall_o) cube(espwall);
        difference() {
            translate([m3_1_o.x - nutbox.x/2, 0.1, -nutbox.z]) cube(nutbox);
            translate([m3_1_o.x - nut.x/2, 3, -m3_zo -nut.z/2]) cube(nut + [10, 0, 0]);
            #translate([m3_1_o.x, 0, -m3_zo]) rotate([-90, 0, 0]) cylinder(h=10, r=m3);
        } 
        difference() {
            translate([m3_2_o.x - nutbox.x/2, pcb.y + wall2.y + extra_y - nutbox.y - 0.1, -nutbox.z]) cube(nutbox);
            translate([m3_2_o.x - nut.x/2, pcb.y + wall2.y + extra_y - 5.1, -m3_zo -nut.z/2]) cube(nut + [10, 0, 0]);
            translate([m3_2_o.x, pcb.y + extra_y - nutbox.y - 0.1, -m3_zo]) rotate([-90, 0, 0]) cylinder(h=10, r=m3);
        }
    } else {
        difference() {
            translate(-wall1) cube(pcb + wall1 + wall2);
            cube(pcb);
            translate([0, pcb.y, 0]) cube([extra_x, wall2.y, height]);
            translate([pcb.x, 15, 0]) cube([wall2.x, pcb.y-30, height]);
            translate([pcb.x, 30, height/2]) cube([wall2.x, pcb.y-30, height/2]);
            translate([8, -wall1.y, 4]) cube([15, wall1.y, height-4]);
            translate(m3_1_o) rotate([-90, 0, 0]) cylinder(h=5, r=m3);
            translate(m3_1_o) rotate([-90, 0, 0]) cylinder(h=1.8, r1=1.8*m3, r2=m3);
            for (x = [0:1]) {
                for (z = [0:1]) {
                    translate([extra_x + 2*wall2.x + 8*x, pcb.y + wall2.y, 10 + 8*z]) rotate([90, 0, 0]) cylinder(h=wall2.y, r=2);
                }
            }
        }
        translate([0, pcb.y + wall2.y, -wall1.z]) cube(extra_floor);
        difference() {
            union() {
                translate([0, pcb.y + wall2.y + extra_y, -wall1.z]) cube([extra_x, wall2.y, wall1.z+height]);
                translate([extra_x, pcb.y + wall2.y, -wall1.z]) cube([wall2.x, extra_y+wall2.y, wall1.z+height]);
            }
            translate(m3_2_o) rotate([90, 0, 0]) cylinder(h=10, r=m3);
            translate(m3_2_o) rotate([90, 0, 0]) cylinder(h=1.8, r1=1.8*m3, r2=m3);
        }
    }
}

module taster(top=false) {
    $fn=60;
    taster_y = 21;
    dim = [26, 71, height];
    wall1 = [0, 2, 2];
    wall2 = [1, 2, 0];
    posl = [dim.x - 0.3, 2, 10];
    posl_o = [0.15, 0.15, -posl.z];
    post = [dim.x - 0.3, 2, 10];
    post_o = [0.15, dim.y - post.y - 0.15, -post.z];
    m3_1_o = [dim.x/2, -wall1.y, dim.z-m3_zo];
    m3_2_o = [dim.x/2, dim.y+wall1.y, dim.z-m3_zo];
    if (top) {
        translate(-wall2) cube([dim.x, dim.y, 0] + wall1 + wall2 + [wall2.x, 0, 0]);
        difference() {
            union() {
                translate([m3_1_o.x - nutbox.x/2, 0.1, -nutbox.z]) cube(nutbox);
                translate(posl_o) cube(posl);
            }
            translate([m3_1_o.x - nut.x/2, 3, -m3_zo -nut.z/2]) cube(nut + [10, 0, 0]);
            #translate([m3_1_o.x, 0, -m3_zo]) rotate([-90, 0, 0]) cylinder(h=10, r=m3);
        } 
        difference() {
            union() {
                translate(post_o) cube(post);
                translate([m3_2_o.x - nutbox.x/2, dim.y - nutbox.y - 0.1, -nutbox.z]) cube(nutbox);
            }
            translate([m3_2_o.x - nut.x/2, dim.y - 5.1, -m3_zo -nut.z/2]) cube(nut + [10, 0, 0]);
            translate([m3_2_o.x, dim.y - nutbox.y - 0.1, -m3_zo]) rotate([-90, 0, 0]) cylinder(h=10, r=m3);
        }
    } else {
        difference() {
            translate(-wall1) cube(dim + wall1 + wall2);
            cube(dim);
            translate([dim.x, 20, 0]) cube([wall2.x, taster_y, height]);
            translate(m3_1_o) rotate([-90, 0, 0]) cylinder(h=5, r=m3);
            translate(m3_1_o) rotate([-90, 0, 0]) cylinder(h=1.8, r1=1.8*m3, r2=m3);
            translate(m3_2_o) rotate([90, 0, 0]) cylinder(h=5, r=m3);
            translate(m3_2_o) rotate([90, 0, 0]) cylinder(h=1.8, r1=1.8*m3, r2=m3);
        }
    }
}

module bottom() {
    battery();
    translate([23.8, 0, 0]) board();
    translate([23.8+59+2, 0, 0]) taster();
}

module top() {
    battery(top=true);
    translate([23.8, 0, 0]) board(top=true);
    translate([23.8+59+2, 0, 0]) taster(top=true);
}

bottom();
translate([0, 0, 22+0]) top();