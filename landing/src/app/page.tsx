import { Features } from "@/components/landing/features";
import { FinalCta } from "@/components/landing/final-cta";
import { Footer } from "@/components/landing/footer";
import { Header } from "@/components/landing/header";
import { Hero } from "@/components/landing/hero";
import { Pricing } from "@/components/landing/pricing";
import { Problems } from "@/components/landing/problems";
import { SocialProof } from "@/components/landing/social-proof";
import { Contact } from "@/components/landing/contact";

export default function Home() {
  return (
    <>
      <Header />
      <main>
        <Hero />
        <Problems />
        <Features />
        <Pricing />
        <SocialProof />
        <Contact />
        <FinalCta />
      </main>
      <Footer />
    </>
  );
}
