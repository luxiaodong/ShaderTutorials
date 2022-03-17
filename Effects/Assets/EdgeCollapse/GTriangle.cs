using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GTriangle
{
	public int m_index0;
	public int m_index1;
	public int m_index2;
	public Matrix4x4 m_mat;

	public void SetIndex(int index0, int index1, int index2)
	{
		m_index0 = index0;
		m_index1 = index1;
		m_index2 = index2;
	}

	public bool IsSame(int index0, int index1, int index2)
	{
		if(m_index0 == index0 && m_index1 == index1 && m_index2 == index2) return true;
		if(m_index0 == index0 && m_index1 == index2 && m_index2 == index1) return true;
		if(m_index0 == index1 && m_index1 == index0 && m_index2 == index2) return true;
		if(m_index0 == index1 && m_index1 == index2 && m_index2 == index0) return true;
		if(m_index0 == index2 && m_index1 == index0 && m_index2 == index1) return true;
		if(m_index0 == index2 && m_index1 == index1 && m_index2 == index0) return true;
		return false;
	}

	public void CalculateMatrix(Vector3 p0, Vector3 p1, Vector3 p2)
	{
		Vector3 v1 = p1 - p0;
		Vector3 v2 = p2 - p0;
		Vector3 n = Vector3.Cross(v1, v2).normalized;
		float d = Vector3.Dot(n, p0);

		if(d > 0)
		{
			d = -d;
		}
		else
		{
			n = -n;
		}

		float a = n.x;
		float b = n.y;
		float c = n.z;

		m_mat = Matrix4x4.zero;
    	m_mat[0,0] += a*a;
    	m_mat[0,1] += a*b;
    	m_mat[0,2] += a*c;
    	m_mat[0,3] += a*d;

    	m_mat[1,0] += b*a;
    	m_mat[1,1] += b*b;
    	m_mat[1,2] += b*c;
    	m_mat[1,3] += b*d;

    	m_mat[2,0] += c*a;
    	m_mat[2,1] += c*b;
    	m_mat[2,2] += c*c;
    	m_mat[2,3] += c*d;

    	m_mat[3,0] += d*a;
    	m_mat[3,1] += d*b;
    	m_mat[3,2] += d*c;
    	m_mat[3,3] += d*d;  
	}

	//删掉这两个点后,这个三角形是否坍塌
	public bool IsCollapse(int one, int other)
	{
		if(m_index0 != one && m_index1 != one && m_index2 != one)
		{
			return false;
		}

		if(m_index0 != other && m_index1 != other && m_index2 != other)
		{
			return false;
		}

		return true;
	}	
}
