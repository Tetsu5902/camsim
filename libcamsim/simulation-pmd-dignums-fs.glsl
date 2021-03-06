/*
 * Copyright (C) 2012, 2013, 2014, 2015, 2016, 2017, 2018
 * Computer Graphics Group, University of Siegen
 * Written by Martin Lambers <martin.lambers@uni-siegen.de>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#version 450

const float hc = 1.98644582; // planck-constant * speed of light in 1e-25 m^3kg/s^2

uniform sampler2D pmd_energies;
uniform float wavelength;               // in nm = 1e-9m
uniform float quantum_efficiency;
uniform int max_electrons;              // maximum number of electrons per pixel

smooth in vec2 vtexcoord;

layout(location = 0) out vec4 pmd_dignums;


#if $SHOT_NOISE$

uniform vec4 random_noise; /* uniformly distributed in [0,1000]; to be set for each frame */

float rnd_uniform(vec2 n)
{
    float r = fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453); /* in [0,1) */
    return 1.0 - r; /* in (0,1]; it is important for Box-Mueller transform that we do not return 0 */
}

vec2 rnd_gauss(vec2 texcoord, vec4 random_offset)
{
    const float two_pi = 6.28318530718;
    // Box-Mueller transform
    vec2 u = vec2(rnd_uniform(texcoord + random_offset.xy), rnd_uniform(texcoord + random_offset.zw));
    return sqrt(-2.0 * log(u.x)) * vec2(cos(two_pi * u.y), sin(two_pi * u.y));
}

#endif

void main(void)
{
    vec2 energies = texture(pmd_energies, vtexcoord).rg;
    // ([1e-9m] * [1e-21 J]) / [1e-25 Jm] = [1e-30]/[1e-25] = 1e-5 electrons
    vec2 electrons = ((quantum_efficiency * wavelength * energies) / hc) / 10000.0;
#if $SHOT_NOISE$
    // Approximation of poisson noise
    electrons += sqrt(electrons) * rnd_gauss(vtexcoord, random_noise);
#endif
    // transform electrons to range [0, 1]
    vec2 dignums = clamp(electrons, vec2(0.0), vec2(max_electrons)) / vec2(max_electrons);
    pmd_dignums = vec4(dignums.x - dignums.y, dignums.x + dignums.y, dignums);
}
