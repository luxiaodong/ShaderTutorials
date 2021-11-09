using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ProjectionShadow : MonoBehaviour
{
	public Transform m_light;
	public Vector4 m_plane;
	
	Vector3 m_lightPos;
	Material m_mat;
	Matrix4x4 m_matrix;

    void Start()
    {
    	m_mat = GetComponent<MeshRenderer>().material;
        m_lightPos = m_light.position;
        CalShadowMatrix();
        
        // TestPoint( new Vector4(-0.5f, 2.0f, -0.5f, 1.0f) );
        // TestPoint( new Vector4(-0.5f, 2.0f, 0.5f, 1.0f) );
        // TestPoint( new Vector4(0.5f, 2.0f, -0.5f, 1.0f) );
        // TestPoint( new Vector4(0.5f, 2.0f, 0.5f, 1.0f) );
    }

    void TestPoint(Vector4 pt)
    {
    	Debug.Log(m_matrix*pt);
    }

    void CalShadowMatrix()
    {
    	Vector3 l = m_lightPos;
    	Vector3 n = m_plane;
		float dot = Vector3.Dot(n, l);
		float d = m_plane.w;

        m_matrix[0,0] = -l.x*n.x + d + dot;
        m_matrix[0,1] = -l.x*n.y;
        m_matrix[0,2] = -l.x*n.z;
        m_matrix[0,3] = -l.x*d;

        m_matrix[1,0] = -l.y*n.x;
        m_matrix[1,1] = -l.y*n.y + d + dot;
        m_matrix[1,2] = -l.y*n.z;
        m_matrix[1,3] = -l.y*d;

        m_matrix[2,0] = -l.z*n.x;
        m_matrix[2,1] = -l.z*n.y;
        m_matrix[2,2] = -l.z*n.z + d + dot;
        m_matrix[2,3] = -l.z*d;

        m_matrix[3,0] = -n.x;
        m_matrix[3,1] = -n.y;
        m_matrix[3,2] = -n.z;
        m_matrix[3,3] = dot;
    }

    void Update()
    {
    	m_lightPos = m_light.position;
    	CalShadowMatrix();
        m_mat.SetMatrix("_ShadowMatrix", m_matrix);
    }
}
