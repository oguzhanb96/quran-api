import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

type Payload = {
  question: string;
  conversation_id: string;
  language_code: string;
};

serve(async (req: Request) => {
  const payload = await req.json() as Payload;
  const answer = {
    answer: "Bu başlangıç fonksiyonudur. Üretim ortamında RAG servisine bağlanmalıdır.",
    citations: [
      { source_type: "quran", reference: "2:255" },
      { source_type: "hadith", reference: "Sahih Bukhari 1" }
    ],
    confidence: 0.6,
    conversation_id: payload.conversation_id,
    language_code: payload.language_code
  };

  return new Response(JSON.stringify(answer), {
    headers: { "content-type": "application/json" },
    status: 200
  });
});
