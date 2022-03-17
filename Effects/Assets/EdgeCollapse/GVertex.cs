using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GVertex
{
	public Matrix4x4 m_mat; //代价矩阵
	public List<GTriangle> m_triangles; //包含该点的三角形
	public bool m_isObsolete;

	public GVertex()
	{
		m_isObsolete = false;
		m_triangles = new List<GTriangle>();
	}

	public void CalculateMatrix()
	{
		m_mat = Matrix4x4.zero;
		foreach(var tri in m_triangles)
		{
			for(int j = 0; j < 4; ++j)
			{
				for(int i = 0; i < 4; ++i)
				{
					m_mat[j,i] += tri.m_mat[j,i];
				}
			}	
		}
	}
}
