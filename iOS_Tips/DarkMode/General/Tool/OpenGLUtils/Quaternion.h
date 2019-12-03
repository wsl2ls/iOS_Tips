//
//  Quaternion.h
//
//  Created by kesalin@gmail.com on 12-12-14.
//  Copyright (c) 2012年 http://blog.csdn.net/kesalin/. All rights reserved.
//

#pragma once

#include "Vector.h"
#include "GLESMath.h"

struct Quaternion
{
    float x;
    float y;
    float z;
    float w;
    
    Quaternion();
    Quaternion(float x, float y, float z, float w);
    
    Quaternion Slerp(float mu, const Quaternion& q) const;
    Quaternion Rotated(const Quaternion& b) const;
    Quaternion Scaled(float scale) const;
    
    float Dot(const Quaternion& q) const;
    void ToMatrix4(KSMatrix4 * m) const;
    Vector4<float> ToVector() const;
    void ToIdentity();
    
    Quaternion operator-(const Quaternion& q) const;
    Quaternion operator+(const Quaternion& q) const;
    bool operator==(const Quaternion& q) const;
    bool operator!=(const Quaternion& q) const;
    
    void Normalize();
    void Rotate(const Quaternion& q);
    
    static Quaternion CreateFromVectors(const Vector3<float>& v0, const Vector3<float>& v1);
    static Quaternion CreateFromAxisAngle(const Vector3<float>& axis, float radians);
};

inline Quaternion::Quaternion() : x(0), y(0), z(0), w(1)
{}

inline Quaternion::Quaternion(float x, float y, float z, float w) : x(x), y(y), z(z), w(w)
{}

inline void Quaternion::ToIdentity()
{
    x = y = z = 0;
    w = 1.0;
}

// Ken Shoemake's famous method.
inline Quaternion Quaternion::Slerp(float t, const Quaternion& v1) const
{
    const float epsilon = 0.0005f;
    float dot = Dot(v1);
    
    if (dot > 1 - epsilon) {
        Quaternion result = v1 + (*this - v1).Scaled(t);
        result.Normalize();
        return result;
    }
    
    if (dot < 0)
        dot = 0;
    
    if (dot > 1)
        dot = 1;
    
    float theta0 = acos(dot);
    float theta = theta0 * t;
    
    Quaternion v2 = (v1 - Scaled(dot));
    v2.Normalize();
    
    Quaternion q = Scaled(cos(theta)) + v2.Scaled(sin(theta));
	q.Normalize();
	return q;
}

inline Quaternion Quaternion::Rotated(const Quaternion& b) const
{
    Quaternion q;
    q.w = w * b.w - x * b.x - y * b.y - z * b.z;
    q.x = w * b.x + x * b.w + y * b.z - z * b.y;
    q.y = w * b.y + y * b.w + z * b.x - x * b.z;
    q.z = w * b.z + z * b.w + x * b.y - y * b.x;
    q.Normalize();
    return q;
}

inline Quaternion Quaternion::Scaled(float s) const
{
    return Quaternion(x * s, y * s, z * s, w * s);
}

inline float Quaternion::Dot(const Quaternion& q) const
{
    return x * q.x + y * q.y + z * q.z + w * q.w;
}

inline void Quaternion::ToMatrix4(KSMatrix4 * result) const
{
    const float s = 2;
    float xs, ys, zs;
    float wx, wy, wz;
    float xx, xy, xz;
    float yy, yz, zz;
    xs = x * s;  ys = y * s;  zs = z * s;
    wx = w * xs; wy = w * ys; wz = w * zs;
    xx = x * xs; xy = x * ys; xz = x * zs;
    yy = y * ys; yz = y * zs; zz = z * zs;
    
    result->m[0][0] = 1 - (yy + zz);
    result->m[0][1] = xy + wz;
    result->m[0][2] = xz - wy;
    result->m[0][3] = 0; 
    
    result->m[1][0] = xy - wz;
    result->m[1][1] = 1 - (xx + zz); 
    result->m[1][2] = yz + wx;
    result->m[1][3] = 0;
    
    result->m[2][0] = xz + wy;
    result->m[2][1] = yz - wx;
    result->m[2][2]= 1 - (xx + yy);
    result->m[2][3] = 0;
    
    result->m[3][0] = 0;
    result->m[3][1] = 0;
    result->m[3][2] = 0;
    result->m[3][3] = 1;
}

inline Vector4<float> Quaternion::ToVector() const
{
    return Vector4<float>(x, y, z, w);
}

inline Quaternion Quaternion::operator-(const Quaternion& q) const
{
    return Quaternion(x - q.x, y - q.y, z - q.z, w - q.w);
}

inline Quaternion Quaternion::operator+(const Quaternion& q) const
{
    return Quaternion(x + q.x, y + q.y, z + q.z, w + q.w);
}

inline bool Quaternion::operator==(const Quaternion& q) const
{
    return x == q.x && y == q.y && z == q.z && w == q.w;
}

inline bool Quaternion::operator!=(const Quaternion& q) const
{
    return !(*this == q);
}

inline void Quaternion::Normalize()
{
    *this = Scaled(1 / sqrt(Dot(*this)));
}

inline void Quaternion::Rotate(const Quaternion& q2)
{
    Quaternion q;
    Quaternion& q1 = *this;
    
    q.w = q1.w * q2.w - q1.x * q2.x - q1.y * q2.y - q1.z * q2.z;
    q.x = q1.w * q2.x + q1.x * q2.w + q1.y * q2.z - q1.z * q2.y;
    q.y = q1.w * q2.y + q1.y * q2.w + q1.z * q2.x - q1.x * q2.z;
    q.z = q1.w * q2.z + q1.z * q2.w + q1.x * q2.y - q1.y * q2.x;
    
    q.Normalize();
    *this = q;
}

// Compute the quaternion that rotates from a to b, avoiding numerical instability.
// Taken from "The Shortest Arc Quaternion" by Stan Melax in "Game Programming Gems".
//
inline Quaternion Quaternion::CreateFromVectors(const Vector3<float>& v0, const Vector3<float>& v1)
{
    if (v0 == -v1)
        return Quaternion::CreateFromAxisAngle(vec3(1, 0, 0), Pi);
    
    Vector3<float> c = v0.Cross(v1);
    float d = v0.Dot(v1);
    float s = sqrt((1 + d) * 2);
    
    Quaternion q;
    q.x = c.x / s;
    q.y = c.y / s;
    q.z = c.z / s;
    q.w = s / 2.0f;
    
    return q;
}

inline Quaternion Quaternion::CreateFromAxisAngle(const Vector3<float>& axis, float radians)
{
    Quaternion q;
    q.w = cos(radians / 2);
    q.x = q.y = q.z = sin(radians / 2);
    q.x *= axis.x;
    q.y *= axis.y;
    q.z *= axis.z;
    
    return q;
}


