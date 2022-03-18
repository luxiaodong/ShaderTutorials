using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GEdge
{
	public int m_index; //在数组m_edgeArray里的索引
	public int m_index1; //两个顶点在m_vertexList的索引
	public int m_index2;
	public Matrix4x4 m_mat;
	public Vector3 m_pt; //新的点
	public float m_cost; //代价,二次误差

	public  GEdge(int index1, int index2)
	{
		m_index1 = index1;
		m_index2 = index2;
	}

	public bool IsSame(int index1, int index2)
	{
		if(m_index1 == index1 && m_index2 == index2) return true;
		if(m_index1 == index2 && m_index2 == index1) return true;
		return false;
	}

	public bool IsEffected(int index1, int index2)
	{
		if(m_index1 == index1 || m_index1 == index2) return true;
		if(m_index2 == index1 || m_index2 == index2) return true;
		return false;
	}

	public void CalculateCost(Matrix4x4 m1, Matrix4x4 m2, Vector3 defaultPt)
	{
		m_mat = Matrix4x4.zero;
		for(int j = 0; j < 4; ++j)
		{
			for(int i = 0; i < 4; ++i)
			{
				m_mat[j,i] = m1[j,i] + m2[j,i];
			}
		}

		//求最小值,导数为0
		Matrix4x4 derMat = m_mat;
		derMat[3,0] = 0;
		derMat[3,1] = 0;
		derMat[3,2] = 0;
		derMat[3,3] = 1;

		Matrix4x4 invMat = derMat.inverse;
		if(invMat[3,3] == 0) //没有逆矩阵
		{
			m_pt = defaultPt;
		}
		else
		{
			m_pt = invMat.MultiplyPoint(Vector3.zero);
		}

		//计算二次形
		float x = m_mat[0,0]*m_pt.x + m_mat[0,1]*m_pt.y + m_mat[0,2]*m_pt.z + m_mat[0,3];
		float y = m_mat[1,0]*m_pt.x + m_mat[1,1]*m_pt.y + m_mat[1,2]*m_pt.z + m_mat[1,3];
		float z = m_mat[2,0]*m_pt.x + m_mat[2,1]*m_pt.y + m_mat[2,2]*m_pt.z + m_mat[2,3];
		float w = m_mat[3,0]*m_pt.x + m_mat[3,1]*m_pt.y + m_mat[3,2]*m_pt.z + m_mat[3,3];
		m_cost = m_pt.x*x + m_pt.y*y + m_pt.z*z + w;
		// m_pt = m_pt*0.01f;
	}
}
