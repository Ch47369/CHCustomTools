using System;
using System.Collections.Generic;
using UnityEngine;

namespace CH.CustomTools.Measurement
{
    internal static class DmGeometry
    {
        public static bool Finite(Vector3 p) { return Finite(p.x) && Finite(p.y) && Finite(p.z); }
        static bool Finite(float x) { return !float.IsNaN(x) && !float.IsInfinity(x); }
        public static bool TryAngle(Vector3 prev, Vector3 vertex, Vector3 next, out float degrees)
        {
            Vector3 a = prev - vertex, b = next - vertex;
            degrees = 0;
            if (!Finite(a) || !Finite(b) || a.sqrMagnitude < 1e-12f || b.sqrMagnitude < 1e-12f) return false;
            degrees = Vector3.Angle(a, b); return true;
        }
        static double Cross(Vector2 a, Vector2 b, Vector2 c) { return ((double)b.x-a.x)*(c.y-a.y)-((double)b.y-a.y)*(c.x-a.x); }
        static bool On(Vector2 a, Vector2 b, Vector2 p, double eps)
        {
            return Math.Abs(Cross(a,b,p)) <= eps && p.x >= Math.Min(a.x,b.x)-1e-6 && p.x <= Math.Max(a.x,b.x)+1e-6 && p.y >= Math.Min(a.y,b.y)-1e-6 && p.y <= Math.Max(a.y,b.y)+1e-6;
        }
        public static bool TryArea(List<Vector3> points, out double area, out string error)
        {
            area = 0; error = null;
            if (points == null || points.Count < 3) { error = DmText.Pick("面积至少需要三个顶点。", "Area requires at least three vertices."); return false; }
            Vector3 origin = points[0]; double nx=0, ny=0, nz=0; float extent=0;
            for (int i=0;i<points.Count;i++)
            {
                if (!Finite(points[i])) { error = DmText.Pick("顶点坐标不是有限数值。", "Vertex coordinates must be finite."); return false; }
                Vector3 a=points[i]-origin, b=points[(i+1)%points.Count]-origin;
                if ((a-b).sqrMagnitude < 1e-12f) { error = DmText.Pick("面积边界包含重合顶点。", "Area boundary contains coincident vertices."); return false; }
                nx+=(double)a.y*b.z-(double)a.z*b.y; ny+=(double)a.z*b.x-(double)a.x*b.z; nz+=(double)a.x*b.y-(double)a.y*b.x;
                extent=Mathf.Max(extent,a.magnitude);
            }
            double norm=Math.Sqrt(nx*nx+ny*ny+nz*nz);
            if (norm < 1e-12) { error = DmText.Pick("面积边界退化或自交。", "Area boundary is degenerate or intersects itself."); return false; }
            Vector3 normal=new Vector3((float)(nx/norm),(float)(ny/norm),(float)(nz/norm));
            int axis=Math.Abs(nx)>=Math.Abs(ny) && Math.Abs(nx)>=Math.Abs(nz)?0:Math.Abs(ny)>=Math.Abs(nz)?1:2;
            var projected=new Vector2[points.Count];
            for (int i=0;i<points.Count;i++)
            {
                Vector3 p=points[i]-origin;
                if (Math.Abs(Vector3.Dot(p,normal)) > Math.Max(1e-5,extent*1e-5)) { error = DmText.Pick("面积只支持共面边界；这不是曲面表面积。", "Area requires a planar boundary; it does not measure curved surface area."); return false; }
                projected[i]=axis==0?new Vector2(p.y,p.z):axis==1?new Vector2(p.x,p.z):new Vector2(p.x,p.y);
            }
            double eps=Math.Max(1e-12,(double)extent*extent*1e-10);
            for(int i=0;i<points.Count;i++) for(int j=i+1;j<points.Count;j++)
            {
                int ii=(i+1)%points.Count,jj=(j+1)%points.Count;
                if(ii==j || jj==i) continue;
                Vector2 a=projected[i],b=projected[ii],c=projected[j],d=projected[jj];
                double abC=Cross(a,b,c),abD=Cross(a,b,d),cdA=Cross(c,d,a),cdB=Cross(c,d,b);
                if ((abC>eps && abD < -eps || abC < -eps && abD>eps) && (cdA>eps && cdB < -eps || cdA < -eps && cdB>eps) || On(a,b,c,eps) || On(a,b,d,eps) || On(c,d,a,eps) || On(c,d,b,eps))
                { error=DmText.Pick("面积边界不能自交或重叠。", "Area boundary must not intersect or overlap itself."); return false; }
            }
            area=norm*.5; return true;
        }
    }
    internal static class DmText
    {
        public static string Pick(string zh, string en) { return ASEShaderConverter.Editor.CHToolLanguage.Pick(zh,en); }
    }
}
