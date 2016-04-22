# Flash-H264Setting-Comparation
Testing the H264Setting to get the most suitable config for production use

First of all Developed by **FlashDevelop** and : good by poor FlashBuilder~

Ok, This is a test demo for testing the suitable H264Setting for live stream and the conclusion is : 

**Best Config**
```
  {
    bandWidth : 0,  // maximum bandwith that you can use 
    quality : 85, // quality for camera higher quality for higher resulution
    fps : 60, // fps for camera 
    width : 640, // camera width 
    height : 480 // camera height
  }
```
  Ok , In general situation, if set `bandWidth=0` it will lead to high resolution of course with high bandWidth cost sametime. But it only happen when the `quality=100`. It's controlable when you set a lower quality like `80/85`.
 
  With this config , you can get high resolution and bandwith cost not so much.
  
  
**General Config**
```
  {
    bandWidth : 60000,  // maximum bandwith that you can use 
    quality : 90, // quality for camera higher quality for higher resulution
    fps : 15, // fps for camera 
    width : 640, // camera width 
    height : 480 // camera height
  }
```
  This is the general config for most case. Limit the bandwith, quality and fps. OK, believe me , you will not like the resolution. :)
