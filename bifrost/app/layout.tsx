import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import NavBar from "@/components/layout/navbar";
import Footer from "@/components/layout/footer";
import "@mintlify/mdx/dist/styles.css";
import { Analytics } from "@vercel/analytics/react";
import { SpeedInsights } from "@vercel/speed-insights/next";
import { PHProvider } from "./providers";
import dynamic from "next/dynamic";
import Script from "next/script";
import Head from "next/head";
import { Layout } from "./components/Layout";
const PostHogPageView = dynamic(() => import("./PostHogPageView"), {
  ssr: false,
});

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "Helicone / LLM-Observability for Developers",
  description:
    "The open-source platform for logging, monitoring, and debugging.",
  icons: "https://www.helicone.ai/static/logo.webp",
  openGraph: {
    type: "website",
    siteName: "Helicone.ai",
    title: "Helicone",
    url: "https://www.helicone.ai",
    description: "LLM-Observability for Developers",
    images: "https://www.helicone.ai/static/new-open-graph.png",
    locale: "en_US",
  },
  twitter: {
    title: "Helicone",
    description: "LLM-Observability for Developers",
    card: "summary_large_image",
    images: "https://www.helicone.ai/static/new-open-graph.png",
  },
};

export default async function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <Head>
        <Head>
          <link rel="shortcut icon" href="/favicon.ico" />
          <link rel="icon" href="/static/logo.png" />
          <link rel="icon" href="/favicon-16x16.png" sizes="16x16" />
          <link rel="icon" href="/favicon-32x32.png" sizes="32x32" />
          <link
            rel="apple-touch-icon"
            href="/apple-touch-icon.png"
            sizes="180x180"
          />
        </Head>
        <link
          rel="icon"
          href="/favicon.ico"
          type="image/x-icon"
          sizes="16x16"
        />
      </Head>
      <PHProvider>
        <body>
          <div className={`bg-white flex flex-col ${inter.className}`}>
            {children}
          </div>
          <PostHogPageView />
          <Analytics />
          <SpeedInsights />
          <Script
            id="koala-snippet"
            dangerouslySetInnerHTML={{
              __html: `!function(t){if(window.ko)return;window.ko=[],["identify","track","removeListeners","open","on","off","qualify","ready"].forEach(function(t){ko[t]=function(){var n=[].slice.call(arguments);return n.unshift(t),ko.push(n),ko}});var n=document.createElement("script");n.async=!0,n.setAttribute("src","https://cdn.getkoala.com/v1/pk_3d24ae9e69e18decfcb68b9d7b668c4501b5/sdk.js"),(document.body || document.head).appendChild(n)}();`,
            }}
          />
          <Script
            id="rb2b-snippet"
            dangerouslySetInnerHTML={{
              __html: `!function(){var reb2b=window.reb2b=window.reb2b||[];if(reb2b.invoked)return;reb2b.invoked=true;reb2b.methods=["identify","collect"];reb2b.factory=function(method){return function(){var args=Array.prototype.slice.call(arguments);args.unshift(method);reb2b.push(args);return reb2b;}};for(var i=0;i<reb2b.methods.length;i++){var key=reb2b.methods[i];reb2b[key]=reb2b.factory(key);}reb2b.load=function(key){var script=document.createElement("script");script.type="text/javascript";script.async=true;script.src="https://s3-us-west-2.amazonaws.com/b2bjsstore/b/"+key+"/LNKLDHM4VMOJ.js.gz";var first=document.getElementsByTagName("script")[0];first.parentNode.insertBefore(script,first);};reb2b.SNIPPET_VERSION="1.0.1";reb2b.load("LNKLDHM4VMOJ");}();`,
            }}
          />
          <Script
            id="google-analytics"
            strategy="afterInteractive"
            src="https://www.googletagmanager.com/gtag/js?id=G-WGDEGPP49F"
          />
          <Script
            id="google-analytics-config"
            strategy="afterInteractive"
            dangerouslySetInnerHTML={{
              __html: `
              window.dataLayer = window.dataLayer || [];
              function gtag(){dataLayer.push(arguments);}
              gtag('js', new Date());
              gtag('config', 'G-WGDEGPP49F');
            `,
            }}
          />
          <Script
            id="warmly-script-loader"
            src="https://opps-widget.getwarmly.com/warmly.js?clientId=489345224dd85359988138e0fb912d04"
            defer
          />
        </body>
      </PHProvider>
    </html>
  );
}
