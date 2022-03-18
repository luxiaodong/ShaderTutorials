using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GMatrix
{
	public double x00, x01, x02, x03;
	public double x10, x11, x12, x13;
	public double x20, x21, x22, x23;
	public double x30, x31, x32, x33;

	public GMatrix()
	{
		this.x00 = 0.0; this.x01 = 0.0; this.x02 = 0.0; this.x03 = 0.0;
        this.x10 = 0.0; this.x11 = 0.0; this.x12 = 0.0; this.x13 = 0.0;
        this.x20 = 0.0; this.x21 = 0.0; this.x22 = 0.0; this.x23 = 0.0;
        this.x30 = 0.0; this.x31 = 0.0; this.x32 = 0.0; this.x33 = 0.0;
	}

	public GMatrix(
        double x00, double x01, double x02, double x03,
        double x10, double x11, double x12, double x13,
        double x20, double x21, double x22, double x23,
        double x30, double x31, double x32, double x33)
        {
            this.x00 = x00; this.x01 = x01;
            this.x02 = x02; this.x03 = x03;
            this.x10 = x10; this.x11 = x11;
            this.x12 = x12; this.x13 = x13;
            this.x20 = x20; this.x21 = x21;
            this.x22 = x22; this.x23 = x23;
            this.x30 = x30; this.x31 = x31;
            this.x32 = x32; this.x33 = x33;
        }
}

public static class GMatrixOperate
{
	public static void Test()
	{
		var m = new GMatrix(
            0.0546, 0.3831, 0.4218, -0.8571,
            0.3831, 2.6875, 2.9590, -6.0130,
            0.4218, 2.9590, 3.2579, -6.6205,
            0, 0, 0, 1.0);

		var invM = m.Inverse();
		invM.Print();
	}

	public static void Print(this GMatrix a)
	{
		Debug.Log("=================================");
		Debug.Log(a.x00+" "+a.x01+" "+a.x02+" "+a.x03);
		Debug.Log(a.x10+" "+a.x11+" "+a.x12+" "+a.x13);
		Debug.Log(a.x20+" "+a.x21+" "+a.x22+" "+a.x23);
		Debug.Log(a.x30+" "+a.x31+" "+a.x32+" "+a.x33);
		Debug.Log("=================================");
	}

	public static double QuadricError(this GMatrix a, Vector3 v)
    {
        return (v.x * a.x00 * v.x + v.y * a.x10 * v.x + v.z * a.x20 * v.x + a.x30 * v.x +
           v.x * a.x01 * v.y + v.y * a.x11 * v.y + v.z * a.x21 * v.y + a.x31 * v.y +
           v.x * a.x02 * v.z + v.y * a.x12 * v.z + v.z * a.x22 * v.z + a.x32 * v.z +
           v.x * a.x03 + v.y * a.x13 + v.z * a.x23 + a.x33);
    }

    public static Vector3 QuadricVector(this GMatrix a)
    {
        var m = new GMatrix(
            a.x00, a.x01, a.x02, a.x03,
            a.x10, a.x11, a.x12, a.x13,
            a.x20, a.x21, a.x22, a.x23,
            0, 0, 0, 1);

        return m.Inverse().MulPosition(new Vector3(0,0,0));
    }

    public static GMatrix Add(this GMatrix a, GMatrix b)
    {
        return new GMatrix(
            a.x00 + b.x00, a.x10 + b.x10, a.x20 + b.x20, a.x30 + b.x30,
            a.x01 + b.x01, a.x11 + b.x11, a.x21 + b.x21, a.x31 + b.x31,
            a.x02 + b.x02, a.x12 + b.x12, a.x22 + b.x22, a.x32 + b.x32,
            a.x03 + b.x03, a.x13 + b.x13, a.x23 + b.x23, a.x33 + b.x33
        );
    }

    public static GMatrix Inverse(this GMatrix a)
    {
        GMatrix m = new GMatrix();
        var r = 1 / Determinant(a);
        m.x00 = (a.x12 * a.x23 * a.x31 - a.x13 * a.x22 * a.x31 + a.x13 * a.x21 * a.x32 - a.x11 * a.x23 * a.x32 - a.x12 * a.x21 * a.x33 + a.x11 * a.x22 * a.x33) * r;
        m.x01 = (a.x03 * a.x22 * a.x31 - a.x02 * a.x23 * a.x31 - a.x03 * a.x21 * a.x32 + a.x01 * a.x23 * a.x32 + a.x02 * a.x21 * a.x33 - a.x01 * a.x22 * a.x33) * r;
        m.x02 = (a.x02 * a.x13 * a.x31 - a.x03 * a.x12 * a.x31 + a.x03 * a.x11 * a.x32 - a.x01 * a.x13 * a.x32 - a.x02 * a.x11 * a.x33 + a.x01 * a.x12 * a.x33) * r;
        m.x03 = (a.x03 * a.x12 * a.x21 - a.x02 * a.x13 * a.x21 - a.x03 * a.x11 * a.x22 + a.x01 * a.x13 * a.x22 + a.x02 * a.x11 * a.x23 - a.x01 * a.x12 * a.x23) * r;
        m.x10 = (a.x13 * a.x22 * a.x30 - a.x12 * a.x23 * a.x30 - a.x13 * a.x20 * a.x32 + a.x10 * a.x23 * a.x32 + a.x12 * a.x20 * a.x33 - a.x10 * a.x22 * a.x33) * r;
        m.x11 = (a.x02 * a.x23 * a.x30 - a.x03 * a.x22 * a.x30 + a.x03 * a.x20 * a.x32 - a.x00 * a.x23 * a.x32 - a.x02 * a.x20 * a.x33 + a.x00 * a.x22 * a.x33) * r;
        m.x12 = (a.x03 * a.x12 * a.x30 - a.x02 * a.x13 * a.x30 - a.x03 * a.x10 * a.x32 + a.x00 * a.x13 * a.x32 + a.x02 * a.x10 * a.x33 - a.x00 * a.x12 * a.x33) * r;
        m.x13 = (a.x02 * a.x13 * a.x20 - a.x03 * a.x12 * a.x20 + a.x03 * a.x10 * a.x22 - a.x00 * a.x13 * a.x22 - a.x02 * a.x10 * a.x23 + a.x00 * a.x12 * a.x23) * r;
        m.x20 = (a.x11 * a.x23 * a.x30 - a.x13 * a.x21 * a.x30 + a.x13 * a.x20 * a.x31 - a.x10 * a.x23 * a.x31 - a.x11 * a.x20 * a.x33 + a.x10 * a.x21 * a.x33) * r;
        m.x21 = (a.x03 * a.x21 * a.x30 - a.x01 * a.x23 * a.x30 - a.x03 * a.x20 * a.x31 + a.x00 * a.x23 * a.x31 + a.x01 * a.x20 * a.x33 - a.x00 * a.x21 * a.x33) * r;
        m.x22 = (a.x01 * a.x13 * a.x30 - a.x03 * a.x11 * a.x30 + a.x03 * a.x10 * a.x31 - a.x00 * a.x13 * a.x31 - a.x01 * a.x10 * a.x33 + a.x00 * a.x11 * a.x33) * r;
        m.x23 = (a.x03 * a.x11 * a.x20 - a.x01 * a.x13 * a.x20 - a.x03 * a.x10 * a.x21 + a.x00 * a.x13 * a.x21 + a.x01 * a.x10 * a.x23 - a.x00 * a.x11 * a.x23) * r;
        m.x30 = (a.x12 * a.x21 * a.x30 - a.x11 * a.x22 * a.x30 - a.x12 * a.x20 * a.x31 + a.x10 * a.x22 * a.x31 + a.x11 * a.x20 * a.x32 - a.x10 * a.x21 * a.x32) * r;
        m.x31 = (a.x01 * a.x22 * a.x30 - a.x02 * a.x21 * a.x30 + a.x02 * a.x20 * a.x31 - a.x00 * a.x22 * a.x31 - a.x01 * a.x20 * a.x32 + a.x00 * a.x21 * a.x32) * r;
        m.x32 = (a.x02 * a.x11 * a.x30 - a.x01 * a.x12 * a.x30 - a.x02 * a.x10 * a.x31 + a.x00 * a.x12 * a.x31 + a.x01 * a.x10 * a.x32 - a.x00 * a.x11 * a.x32) * r;
        m.x33 = (a.x01 * a.x12 * a.x20 - a.x02 * a.x11 * a.x20 + a.x02 * a.x10 * a.x21 - a.x00 * a.x12 * a.x21 - a.x01 * a.x10 * a.x22 + a.x00 * a.x11 * a.x22) * r;
        return m;
    }

    public static double Determinant(this GMatrix a)
    {
        return (a.x00 * a.x11 * a.x22 * a.x33 - a.x00 * a.x11 * a.x23 * a.x32 +
            a.x00 * a.x12 * a.x23 * a.x31 - a.x00 * a.x12 * a.x21 * a.x33 +
            a.x00 * a.x13 * a.x21 * a.x32 - a.x00 * a.x13 * a.x22 * a.x31 -
            a.x01 * a.x12 * a.x23 * a.x30 + a.x01 * a.x12 * a.x20 * a.x33 -
            a.x01 * a.x13 * a.x20 * a.x32 + a.x01 * a.x13 * a.x22 * a.x30 -
            a.x01 * a.x10 * a.x22 * a.x33 + a.x01 * a.x10 * a.x23 * a.x32 +
            a.x02 * a.x13 * a.x20 * a.x31 - a.x02 * a.x13 * a.x21 * a.x30 +
            a.x02 * a.x10 * a.x21 * a.x33 - a.x02 * a.x10 * a.x23 * a.x31 +
            a.x02 * a.x11 * a.x23 * a.x30 - a.x02 * a.x11 * a.x20 * a.x33 -
            a.x03 * a.x10 * a.x21 * a.x32 + a.x03 * a.x10 * a.x22 * a.x31 -
            a.x03 * a.x11 * a.x22 * a.x30 + a.x03 * a.x11 * a.x20 * a.x32 -
            a.x03 * a.x12 * a.x20 * a.x31 + a.x03 * a.x12 * a.x21 * a.x30);
    }

    public static Vector3 MulPosition(this GMatrix a, Vector3 b)
    {
    	float x = (float)(a.x00 * b.x + a.x01 * b.y + a.x02 * b.z + a.x03);
    	float y = (float)(a.x10 * b.x + a.x11 * b.y + a.x12 * b.z + a.x13);
    	float z = (float)(a.x20 * b.x + a.x21 * b.y + a.x22 * b.z + a.x23);
        return new Vector3(x,y,z);
    }

}
