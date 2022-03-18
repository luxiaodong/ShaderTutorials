using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class EdgeCollapse : MonoBehaviour
{
	private List<Vector3> m_verticesList;	//顶点列表
	private List<int> m_trianglesIndexList;	//三角形索引列表
	private int m_trianglesCount;

	private List<GVertex> m_vertexList; //存储顶点其他数据的列表
	private List<GEdge> m_edgeList; //存储边的信息
	private GEdge[] m_edgeArray; //存储边信息的数组形式
	private List<GTriangle> m_triangleList; //存储三角形信息
	private Mesh m_mesh; //最终传给shader的mesh

	private int m_frameIndex;
	private int m_edgeCount; //边塌缩的总个数

	// 坍塌的数据
	private GEdge m_edge; //当前的坍塌边
	private List<int> m_effectTrianglesIndexList;
	private List<GEdge> m_effectEdgeList;
	private List<GTriangle> m_effectTriangleList;

    void Start()
    {
    	// 0.初始化数据
    	Debug.Log("0. =>" + Time.realtimeSinceStartup);

    	Mesh mesh = GetComponent<MeshFilter>().mesh;
    	m_verticesList = new List<Vector3>(mesh.vertices);
    	m_trianglesIndexList = new List<int>(mesh.triangles);
    	m_trianglesCount = m_trianglesIndexList.Count/3;

    	m_vertexList = new List<GVertex>();
    	m_edgeList = new List<GEdge>();
    	m_triangleList = new List<GTriangle>();
    	
    	for (int i = 0; i < m_verticesList.Count; i++)
    	{
    		GVertex vertex = new GVertex();
    		m_vertexList.Add(vertex);
    	}

    	m_mesh = new Mesh();
    	GetComponent<MeshFilter>().mesh = m_mesh;
    	m_frameIndex = 0;

    	// 1.计算初始点矩阵Q, 建立顶点周边关系
    	Debug.Log("1. =>" + Time.realtimeSinceStartup);
    	CreateVertexMatrix();
    	
    	// 2.选择有效的边
    	Debug.Log("2. =>" + Time.realtimeSinceStartup);
    	SelectValidEdge();

    	// 3.计算每条边的塌缩代价
    	Debug.Log("3. =>" + Time.realtimeSinceStartup);
    	CalculateCollapseCost();

    	// 4.构造最小堆
    	Debug.Log("4. =>" + Time.realtimeSinceStartup);
    	m_edgeArray = m_edgeList.ToArray();
    	for(int i = 0; i < m_edgeArray.Length; ++i)
    	{
    		m_edgeArray[i].m_index = i;
    	}
    	CreateMinHeap();

    	// 5.用新数据开始显示
    	Debug.Log("5. =>" + Time.realtimeSinceStartup);
    	m_edgeCount = m_edgeArray.Length;
    	m_mesh.vertices = m_verticesList.ToArray();
    	m_mesh.triangles = m_trianglesIndexList.ToArray();
    	GetComponent<MeshFilter>().mesh = m_mesh;
    	Debug.Log("m_edgeCount is " + m_edgeCount);

    	m_effectTrianglesIndexList = new List<int>();
		m_effectEdgeList = new List<GEdge>();
		m_effectTriangleList = new List<GTriangle>();
    }

	Vector3 GetVertices(int index)
    {
    	// return m_verticesList[index]*100.0f;
    	return m_verticesList[index];
    }

    void CreateVertexMatrix()
    {
    	for (int i = 0; i < m_trianglesCount; i++)
    	{
    		int index0 = m_trianglesIndexList[3*i];
    		int index1 = m_trianglesIndexList[3*i+1];
    		int index2 = m_trianglesIndexList[3*i+2];

    		Vector3 p0 = GetVertices(index0);
    		Vector3 p1 = GetVertices(index1);
    		Vector3 p2 = GetVertices(index2);

    		GTriangle tri = new GTriangle();
    		tri.SetIndex(index0, index1, index2);
    		tri.CalculateMatrix(p0, p1, p2);
    		m_triangleList.Add(tri);

    		if(index0 == 325 || index1 == 325 || index2 == 325)
    		{
    			Debug.Log("=====> " +index0+","+index1+","+index2);
    		}

    		m_vertexList[index0].m_triangles.Add(tri);
    		m_vertexList[index1].m_triangles.Add(tri);
    		m_vertexList[index2].m_triangles.Add(tri);
    	}

    	for (int i = 0; i < m_verticesList.Count; i++)
    	{
    		m_vertexList[i].CalculateMatrix();
    	}
    }

    void SelectValidEdge()
    {
    	int threshold = 1;

    	for (int i = 0; i < m_trianglesCount; i++)
    	{
    		int index0 = m_trianglesIndexList[3*i];
    		int index1 = m_trianglesIndexList[3*i+1];
    		int index2 = m_trianglesIndexList[3*i+2];

    		if(m_vertexList[index0].m_triangles.Count > threshold && 
    		   m_vertexList[index1].m_triangles.Count > threshold)
    		{
    			AppendEdge(index0, index1);
    		}

    		if(m_vertexList[index0].m_triangles.Count > threshold && 
    		   m_vertexList[index2].m_triangles.Count > threshold)
    		{
    			AppendEdge(index0, index2);
    		}

    		if(m_vertexList[index1].m_triangles.Count > threshold && 
    		   m_vertexList[index2].m_triangles.Count > threshold)
    		{
    			AppendEdge(index1, index2);
    		}
    	}
    }

  	void AppendEdge(int index1, int index2)
    {
    	foreach (GEdge edge in m_edgeList)
    	{
    		if(edge.IsSame(index1, index2)) return ;
    	}

    	GEdge newEdge = new GEdge(index1, index2);
    	m_edgeList.Add(newEdge);
    }

    void CalculateCollapseCost()
    {
    	foreach (GEdge edge in m_edgeList)
    	{
    		int index1 = edge.m_index1;
    		int index2 = edge.m_index2;

    		Vector3 p1 = GetVertices(index1);
    		Vector3 p2 = GetVertices(index2);

    		Matrix4x4 m1 = m_vertexList[index1].m_mat;
    		Matrix4x4 m2 = m_vertexList[index2].m_mat;

    		edge.CalculateCost(m1, m2, (p1+p2)*0.5f);
    	}
    }

    void CreateMinHeap()
    {
    	int length = m_edgeArray.Length;
    	for(int i = (length-1)/2; i >=0; i--)
    	{
    		HeapSort(length, i);
    	}

    	// TestHeapSort(length);
    }

	// 最小堆排序
    void HeapSort(int length, int i)
    {
    	int leftIndex = 2*i + 1;
    	int rightIndex = leftIndex + 1;
    	int minIndex = i;

    	if(leftIndex < length)
    	{
    		if(m_edgeArray[leftIndex].m_cost < m_edgeArray[minIndex].m_cost)
    		{
    			minIndex = leftIndex;
    		}
    	}

    	if(rightIndex < length)
    	{
    		if(m_edgeArray[rightIndex].m_cost < m_edgeArray[minIndex].m_cost)
    		{
    			minIndex = rightIndex;
    		}
    	}

    	if(i != minIndex)
    	{
    		SwapEdge(i, minIndex);
    		HeapSort(length, minIndex);
    	}
    }

    //堆上某个数据变化
    void AdjustHeap(int length, int i)
    {
    	if(i == 0)
    	{
    		HeapSort(length, 0);
    		return ;
    	}

    	int parentIndex = i/2;

    	if(m_edgeArray[i].m_cost > m_edgeArray[parentIndex].m_cost)
    	{
    		//往下走
    		HeapSort(length, i);
    		return ;
    	}
    	else
    	{
    		//往上走
    		int myIndex = i;
    		while(m_edgeArray[myIndex].m_cost < m_edgeArray[parentIndex].m_cost)
    		{
    			SwapEdge(myIndex, parentIndex);
    			myIndex = parentIndex;
    			parentIndex = myIndex/2;

    			if(myIndex == parentIndex) break; //两个0的时候退出
    		}
    	}
    }

    void TestHeapSort(int length)
    {
    	Debug.Log("Before Sort");
    	for(int i = 0; i < length; ++i)
    	{
    		Debug.Log(m_edgeArray[i].m_cost);
    	}

    	for(int j = length - 1; j > 0; )
    	{
    		SwapEdge(j, 0);
    		j--;
    		HeapSort(j, 0);
    	}

    	Debug.Log("After Sort");
		for(int i = 0; i < length; ++i)
    	{
    		Debug.Log(m_edgeArray[i].m_cost);
    	}
    }

    void SwapEdge(int i, int j)
    {
    	GEdge temp = m_edgeArray[j];
		m_edgeArray[j] = m_edgeArray[i];
		m_edgeArray[i] = temp;

		m_edgeArray[i].m_index = i;
		m_edgeArray[j].m_index = j;
    }

    // ========================================================

    void UpdateMesh()
    {
		// 从堆中删除最小的边
    	m_edge = m_edgeArray[0];
    	m_edgeList.Remove(m_edge);

    	Debug.Log("m_edge : " + m_edge.m_index1 + "," + m_edge.m_index2);
    	Debug.Log(m_edge.m_pt.ToString("f4"));
    	Debug.Log(m_verticesList[0].ToString("f4"));
    	if(true) return ;

    	// 删掉两个顶点
    	m_vertexList[m_edge.m_index1].m_isObsolete = true;
    	m_vertexList[m_edge.m_index2].m_isObsolete = true;

		// 新增一个顶点
		int newPtIndex = m_verticesList.Count;
		m_verticesList.Add(m_edge.m_pt);
		GVertex vertex = new GVertex();
		m_vertexList.Add(vertex);
		vertex.m_mat = m_edge.m_mat; // 新的顶点代价矩阵用边的代价矩阵
		// vertex.m_triangles // 新顶点关联哪些三角形

		// 找出受影响的边 和 顶点
    	m_effectEdgeList.Clear();
    	m_effectTrianglesIndexList.Clear();
    	m_effectTrianglesIndexList.Add(newPtIndex);
    	foreach (GEdge edge in m_edgeList)
    	{
    		if( edge.IsEffected(m_edge.m_index1, m_edge.m_index2) )
    		{
    			m_effectEdgeList.Add(edge);

    			int index0 = -1;
    			//不是坍塌的点
    			if((edge.m_index1 != m_edge.m_index1) && (edge.m_index1 != m_edge.m_index2))
    			{
    				index0 = edge.m_index1;
    			}
    			
    			if((edge.m_index2 != m_edge.m_index1) && (edge.m_index2 != m_edge.m_index2))
    			{
    				index0 = edge.m_index2;
    			}

    			if(index0 == -1) Debug.LogError("error");

    			bool isExist = false;
    			foreach (int i in m_effectTrianglesIndexList)
    			{
    				if(i == index0)
    				{
    					isExist = true;
    					break;
    				}
    			}

    			if(isExist == false)
    			{
    				m_effectTrianglesIndexList.Add(index0);
    			}
    		}
    	}

		Debug.Log("effectEdgeList");
    	foreach (GEdge edge in m_effectEdgeList)
    	{
    		Debug.Log("edge : " + edge.m_index1 + "," + edge.m_index2);
    	}

    	Debug.Log("effectTrianglesIndexList");
    	foreach (int i in m_effectTrianglesIndexList)
    	{
    		Debug.Log("effectTrianglesIndexList :" + i);
    	}

    	Debug.Log("========GTriangle in vertex list=========");

    	// 找出受影响的三角形
    	m_effectTriangleList.Clear();
    	m_effectTriangleList = m_vertexList[m_edge.m_index1].m_triangles;

    	foreach (GTriangle tri in m_vertexList[m_edge.m_index2].m_triangles)
    	{
    		bool isExist = false;
    		for(int i = 0; i < m_effectTriangleList.Count; ++i)
    		{
    			if(m_effectTriangleList[i] == tri)
    			{
    				isExist = true;
    			}
    		}

    		if(isExist == false)
    		{
    			m_effectTriangleList.Add(tri);
    		}
    	}

    	// 删掉坍塌的三角形, 以及索引
    	for(int i = 0; i < m_effectTriangleList.Count; ++i)
    	{
    		GTriangle tri = m_effectTriangleList[i];
    		if(tri.IsCollapse(m_edge.m_index1, m_edge.m_index2) == true)
    		{
    			m_vertexList[tri.m_index0].m_triangles.Remove(tri);
				m_vertexList[tri.m_index1].m_triangles.Remove(tri);
				m_vertexList[tri.m_index2].m_triangles.Remove(tri);
    			m_triangleList.Remove(tri);
    			m_effectTriangleList.Remove(tri);
    		}
    	}

    	Debug.Log("effectTriangleList");
    	foreach (GTriangle tri in m_effectTriangleList)
    	{
    		Debug.Log("tri : " + tri.m_index0 + "," + tri.m_index1 + "," + tri.m_index2);
    	}

    	// 修改边的值
    	foreach (GEdge edge in m_effectEdgeList)
    	{
    		if (edge.m_index1 == m_edge.m_index1 || edge.m_index1 == m_edge.m_index2)
    		{
    			edge.m_index1 = newPtIndex;
    		}

    		if (edge.m_index2 == m_edge.m_index1 || edge.m_index2 == m_edge.m_index2)
    		{
    			edge.m_index2 = newPtIndex;
    		}

    		if(edge.m_index1 == edge.m_index2) Debug.LogError("error.");
    	}

    	Debug.Log("effectEdgeList changed");
    	foreach (GEdge edge in m_effectEdgeList)
    	{
    		Debug.Log("edge : " + edge.m_index1 + "," + edge.m_index2);
    	}

    	// 修改三角形顶点
    	foreach (GTriangle tri in m_effectTriangleList)
    	{
    		if (tri.m_index0 == m_edge.m_index1 || tri.m_index0 == m_edge.m_index2)
    		{
    			tri.m_index0 = newPtIndex;
    		}

    		if (tri.m_index1 == m_edge.m_index1 || tri.m_index1 == m_edge.m_index2)
    		{
    			tri.m_index1 = newPtIndex;
    		}

    		if (tri.m_index2 == m_edge.m_index1 || tri.m_index2 == m_edge.m_index2)
    		{
    			tri.m_index2 = newPtIndex;
    		}

    		//更新平面的代价矩阵
    		Vector3 p0 = GetVertices(tri.m_index0);
    		Vector3 p1 = GetVertices(tri.m_index1);
    		Vector3 p2 = GetVertices(tri.m_index2);
    		tri.CalculateMatrix(p0, p1, p2);
    	}

    	Debug.Log("effectTriangleList changed");
    	foreach (GTriangle tri in m_effectTriangleList)
    	{
    		Debug.Log("tri : " + tri.m_index0 + "," + tri.m_index1 + "," + tri.m_index2);
    	}

    	// 更新顶点的代价矩阵
    	foreach (int i in m_effectTrianglesIndexList)
    	{
    		m_vertexList[i].CalculateMatrix();
    	}

    	// 更新边的代价矩阵
    	int lastIndex = m_edgeCount - m_frameIndex;
    	foreach (GEdge edge in m_effectEdgeList)
    	{
    		int index1 = edge.m_index1;
    		int index2 = edge.m_index2;

    		Vector3 p1 = GetVertices(index1);
    		Vector3 p2 = GetVertices(index2);

    		Matrix4x4 m1 = m_vertexList[index1].m_mat;
    		Matrix4x4 m2 = m_vertexList[index2].m_mat;

    		edge.CalculateCost(m1, m2, (p1+p2)*0.5f);

    		//更新堆栈
    		AdjustHeap(lastIndex, edge.m_index);
    	}

    	//最终赋值
    	m_mesh.vertices = m_verticesList.ToArray();
    	int[] vertexArray = new int[m_triangleList.Count * 3];
    	int index = 0;
    	foreach (GTriangle tri in m_triangleList)
    	{
    		vertexArray[index] = tri.m_index0;
    		index++;
    		vertexArray[index] = tri.m_index1;
    		index++;
    		vertexArray[index] = tri.m_index2;
    		index++;
    	}

    	m_mesh.triangles = vertexArray;
    	GetComponent<MeshFilter>().mesh = m_mesh;
    	Debug.Log("m_edgeCount is " + m_edgeCount + " = " + m_frameIndex + " + " + m_edgeList.Count);
    }

    void TestCode()
    {
    }

    // Update is called once per frame
    void Update()
    {
    	m_frameIndex++;
    	// if(m_frameIndex < m_edgeCount)
    	if(m_frameIndex < 2)
    	{
    		UpdateMesh();
    		// TestCode();
    	}
    }
}

	// Debug.Log("设备名称:"+SystemInfo.deviceName);
    // Debug.Log("设备模型:"+SystemInfo.deviceModel);
    // Debug.Log("设备类型:"+SystemInfo.deviceType);
    // Debug.Log("设备标识ID:"+SystemInfo.deviceUniqueIdentifier);
    // Debug.Log("操作系统:"+SystemInfo.operatingSystem);
    // Debug.Log("CPU类型:"+SystemInfo.processorType);
    // Debug.Log("CPU数量:"+SystemInfo.processorCount);
    // Debug.Log("CPU频率:"+SystemInfo.processorFrequency+"MHz");
    // Debug.Log("系统内存:"+SystemInfo.systemMemorySize+"M");
    // Debug.Log("屏幕尺寸:"+Screen.width+"x"+Screen.height);
    // Debug.Log("显卡名称:"+SystemInfo.graphicsDeviceName);
    // Debug.Log("显卡供应商:"+SystemInfo.graphicsDeviceVendor);
    // Debug.Log("显卡供应唯一ID:"+SystemInfo.graphicsDeviceVendorID);
    // Debug.Log("显卡类型:"+SystemInfo.graphicsDeviceType);
    // Debug.Log("显卡标识ID:"+SystemInfo.graphicsDeviceID);
    // Debug.Log("显卡版本:"+SystemInfo.graphicsDeviceVersion);
    // Debug.Log("显卡内存"+SystemInfo.graphicsMemorySize+"M");
    // Debug.Log("显卡支持的渲染目标数量:"+SystemInfo.supportedRenderTargetCount);
    // Debug.Log("显卡最大材质尺寸:"+SystemInfo.maxTextureSize);
    // Debug.Log("显卡是否支持多线程渲染:"+SystemInfo.graphicsMultiThreaded);
    // Debug.Log("电量:"+SystemInfo.batteryLevel);
    // Debug.Log("电池状态:"+SystemInfo.batteryStatus);
	        