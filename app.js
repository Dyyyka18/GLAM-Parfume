const LOGO='assets/logo.png';document.querySelectorAll('.logoimg').forEach(i=>i.src=LOGO);document.getElementById('favicon').href=LOGO;
const $=id=>document.getElementById(id);
const esc=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const D0=()=>new Date().toLocaleDateString('sv-SE');
const code=x=>'BRG-'+String(x.id).padStart(3,'0');
// ---- Supabase (isi URL & anon key di config.js) ----
const CFG=window.GLAM_CONFIG||{};
const sb=(window.supabase&&CFG.SUPABASE_URL&&!/YOUR/i.test(CFG.SUPABASE_URL))?window.supabase.createClient(CFG.SUPABASE_URL,CFG.SUPABASE_ANON_KEY,{auth:{storage:window.sessionStorage}}):null;
// barang: s0=stok_awal, min=stok_minimum, stock=stok_saat_ini | tx: gabungan stok_masuk & stok_keluar
let items=[],tx=[],KATID={},page='dashboard',editing=null,range='semua';
const sum=(id,type)=>tx.filter(t=>t.item===id&&t.type===type).reduce((a,t)=>a+t.qty,0);
const calcS=x=>Math.round((x.s0+sum(x.id,'masuk')-sum(x.id,'keluar'))*100)/100;   // S = S0 + ΣIn − ΣOut
const emailOf=u=>u.includes('@')?u:u+'@glamparfume.local';
async function loadAll(){
 let rs=await Promise.all([sb.from('kategori').select('*'),sb.from('barang').select('*').order('id_barang'),sb.from('stok_masuk').select('*').order('tanggal',{ascending:false}),sb.from('stok_keluar').select('*').order('tanggal',{ascending:false})]);
 let e=rs.find(r=>r.error);if(e){toast('Gagal memuat data: '+e.error.message,5000);return false}
 let [k,b,m,o]=rs.map(r=>r.data),kn={};KATID={};k.forEach(r=>{KATID[r.nama_kategori]=r.id_kategori;kn[r.id_kategori]=r.nama_kategori});
 items=b.map(r=>({id:r.id_barang,cat:kn[r.id_kategori],name:r.nama_barang,unit:r.satuan,s0:+r.stok_awal,stock:+r.stok_saat_ini,min:+r.stok_minimum,note:r.keterangan||''}));
 tx=[...m.map(r=>({id:r.id_stok_masuk,type:'masuk',date:r.tanggal,item:r.id_barang,qty:+r.jumlah,supplier:r.supplier||'',note:r.keterangan||''})),...o.map(r=>({id:r.id_stok_keluar,type:'keluar',date:r.tanggal,item:r.id_barang,qty:+r.jumlah,supplier:'',note:r.keterangan||''}))];
 return true}
async function enter(){if(!await loadAll())return;let pr=CFG.TANPA_LOGIN?{}:await sb.from('users').select('nama').maybeSingle(),nm=(pr.data&&pr.data.nama)||'Pemilik Toko';$('userName').textContent=nm;$('userAvatar').textContent=nm.trim().charAt(0).toUpperCase()||'A';$('login').style.display='none';go('dashboard');if(!CFG.TANPA_LOGIN)toast('Berhasil masuk ke GLAM Parfume');setTimeout(showNotif,500)}
const rup=(n)=>Number(n).toLocaleString('id-ID');
const today=()=>new Date().toLocaleDateString('id-ID',{weekday:'long',day:'numeric',month:'long',year:'numeric'});
document.getElementById('dateText').textContent=today();
const low=()=>items.filter(x=>x.stock<=x.min);
function go(p){page=p;document.querySelectorAll('.nav button').forEach(b=>b.classList.toggle('active',b.dataset.page===p));document.getElementById('crumb').textContent=({dashboard:'Dashboard',barang:'Master Barang',masuk:'Stok Masuk',keluar:'Stok Keluar',rekap:'Rekap Stok',laporan:'Laporan'})[p];render();document.getElementById('sidebar').classList.remove('open')}
document.querySelectorAll('.nav button').forEach(b=>b.onclick=()=>go(b.dataset.page));
document.getElementById('scrim').onclick=()=>document.getElementById('sidebar').classList.remove('open');
function labelTables(){document.querySelectorAll('#content table').forEach(t=>{const h=[...t.querySelectorAll('thead th')].map(x=>x.textContent.trim());t.querySelectorAll('tbody tr').forEach(tr=>[...tr.children].forEach((td,i)=>{if(!td.classList.contains('empty'))td.setAttribute('data-label',h[i]||'')}))})}
new MutationObserver(labelTables).observe(document.getElementById('content'),{childList:true,subtree:true});
document.getElementById('mobilemenu').onclick=()=>document.getElementById('sidebar').classList.toggle('open');
document.getElementById('logout').onclick=async
