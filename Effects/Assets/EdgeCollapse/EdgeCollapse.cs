using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class EdgeCollapse : MonoBehaviour
{
    // Start is called before the first frame update
    void Start()
    {
    	Debug.Log("设备名称:"+SystemInfo.deviceName);
	    Debug.Log("设备模型:"+SystemInfo.deviceModel);
	    Debug.Log("设备类型:"+SystemInfo.deviceType);
	    Debug.Log("设备标识ID:"+SystemInfo.deviceUniqueIdentifier);
	    Debug.Log("操作系统:"+SystemInfo.operatingSystem);
	    Debug.Log("CPU类型:"+SystemInfo.processorType);
	    Debug.Log("CPU数量:"+SystemInfo.processorCount);
	    Debug.Log("CPU频率:"+SystemInfo.processorFrequency+"MHz");
	    Debug.Log("系统内存:"+SystemInfo.systemMemorySize+"M");
	    Debug.Log("屏幕尺寸:"+Screen.width+"x"+Screen.height);
	    Debug.Log("显卡名称:"+SystemInfo.graphicsDeviceName);
	    Debug.Log("显卡供应商:"+SystemInfo.graphicsDeviceVendor);
	    Debug.Log("显卡供应唯一ID:"+SystemInfo.graphicsDeviceVendorID);
	    Debug.Log("显卡类型:"+SystemInfo.graphicsDeviceType);
	    Debug.Log("显卡标识ID:"+SystemInfo.graphicsDeviceID);
	    Debug.Log("显卡版本:"+SystemInfo.graphicsDeviceVersion);
	    Debug.Log("显卡内存"+SystemInfo.graphicsMemorySize+"M");
	    Debug.Log("显卡支持的渲染目标数量:"+SystemInfo.supportedRenderTargetCount);
	    Debug.Log("显卡最大材质尺寸:"+SystemInfo.maxTextureSize);
	    Debug.Log("显卡是否支持多线程渲染:"+SystemInfo.graphicsMultiThreaded);
	    Debug.Log("电量:"+SystemInfo.batteryLevel);
	    Debug.Log("电池状态:"+SystemInfo.batteryStatus);
	        
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
