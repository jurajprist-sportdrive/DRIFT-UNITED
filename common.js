const conf=window.DRIFT_CONFIG||{};
const configured=Boolean(conf.supabaseUrl&&conf.supabaseAnonKey);
const db=configured?window.supabase.createClient(conf.supabaseUrl,conf.supabaseAnonKey):null;
const $=id=>document.getElementById(id);
const escapeText=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
function msg(text,kind=''){const m=$('message');m.textContent=text;m.className='notice '+kind;m.classList.remove('hidden')}
async function sessionProfile(){if(!db)return null;const {data:{user},error}=await db.auth.getUser();if(error||!user)return null;const {data:profile,error:pe}=await db.from('profiles').select('*').eq('id',user.id).single();if(pe)throw pe;return {user,profile}}
async function logout(){await db?.auth.signOut();location.href='portal.html'}
function fail(e){msg(e?.message||String(e),'error')}
