import type {Metadata,Viewport} from "next";import "./globals.css";
export const metadata:Metadata={title:"GUZA GURA — Buy and sell in Western Uganda",description:"Discover local products and sellers in Mbarara and Western Uganda.",applicationName:"GUZA GURA",manifest:"/manifest.webmanifest",appleWebApp:{capable:true,statusBarStyle:"default",title:"GUZA GURA"}};
export const viewport:Viewport={themeColor:"#123d2c",width:"device-width",initialScale:1};
export default function RootLayout({children}:{children:React.ReactNode}){return <html lang="en"><body>{children}</body></html>}
