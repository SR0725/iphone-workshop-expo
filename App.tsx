import React, { useEffect, useRef, useState } from 'react';
import { StatusBar } from 'expo-status-bar';
import { Feather } from '@expo/vector-icons';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { SafeAreaProvider, SafeAreaView } from 'react-native-safe-area-context';
import { ActivityIndicator, KeyboardAvoidingView, Platform, Pressable, ScrollView, StyleSheet, Text, TextInput, View } from 'react-native';

const STORAGE_KEY = 'small-things-workshop-v1';
const categories = ['生活', '工作', '靈感'] as const;
type Category = typeof categories[number];
type Entry = { id: string; title: string; body: string; category: Category; createdAt: string };
type Draft = Omit<Entry, 'id' | 'createdAt'>;
const emptyDraft: Draft = { title: '', body: '', category: '生活' };
const color = { green: '#176B53', ink: '#172921', muted: '#66736D', border: '#DDE5E0', coral: '#D95D4B' };

function isEntry(item: unknown): item is Entry {
  if (!item || typeof item !== 'object') return false;
  const e = item as Entry;
  return typeof e.id === 'string' && typeof e.title === 'string' && typeof e.body === 'string' && categories.includes(e.category) && typeof e.createdAt === 'string';
}

function Journal() {
  const [entries, setEntries] = useState<Entry[]>([]);
  const [ready, setReady] = useState(false);
  const [loadError, setLoadError] = useState(false);
  const [message, setMessage] = useState('');
  const [filter, setFilter] = useState<Category | '全部'>('全部');
  const [editing, setEditing] = useState<string | null | undefined>(undefined);
  const [draft, setDraft] = useState<Draft>(emptyDraft);
  const [deleting, setDeleting] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const busy = useRef(false);

  async function load() {
    setReady(false); setLoadError(false);
    try {
      const raw = await AsyncStorage.getItem(STORAGE_KEY);
      const parsed = raw === null ? [] : JSON.parse(raw);
      if (!Array.isArray(parsed) || !parsed.every(isEntry)) throw new Error('Invalid saved data');
      setEntries(parsed); setReady(true);
    } catch {
      setLoadError(true);
    }
  }
  useEffect(() => { void load(); }, []);

  async function persist(next: Entry[], success: string) {
    if (busy.current || !ready) return false;
    busy.current = true; setSaving(true); setMessage('');
    try {
      await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(next));
      setEntries(next); setMessage(success); return true;
    } catch {
      setMessage('儲存失敗，內容還在。請確認裝置空間後再試一次。'); return false;
    } finally { busy.current = false; setSaving(false); }
  }

  function openEditor(entry?: Entry) {
    setDraft(entry ? { title: entry.title, body: entry.body, category: entry.category } : { ...emptyDraft });
    setEditing(entry?.id ?? null); setMessage(''); setDeleting(null);
  }

  async function save() {
    if (!draft.title.trim()) { setMessage('請先填寫標題'); return; }
    const existing = entries.find(e => e.id === editing);
    const entry: Entry = { ...draft, title: draft.title.trim(), body: draft.body.trim(), id: existing?.id ?? `${Date.now()}-${Math.random().toString(36).slice(2,9)}`, createdAt: existing?.createdAt ?? new Date().toISOString() };
    const next = existing ? entries.map(e => e.id === existing.id ? entry : e) : [entry, ...entries];
    if (await persist(next, '已儲存')) { setEditing(undefined); setFilter('全部'); }
  }

  const shown = entries.filter(e => filter === '全部' || e.category === filter);
  return <SafeAreaView style={s.safe}>
    <StatusBar style="dark" />
    <KeyboardAvoidingView style={s.flex} behavior={Platform.OS === 'ios' ? 'padding' : undefined}>
      <ScrollView contentContainerStyle={s.page} keyboardShouldPersistTaps="handled">
        {editing === undefined ? <>
          <View style={s.header}><View style={s.flex}><Text style={s.eyebrow}>SMALL THINGS</Text><Text style={s.title}>今天的小事</Text></View><View style={s.brand}><Feather name="sun" size={30} color={color.coral} /></View></View>
          <View style={s.summary}><Text style={s.count}>{entries.length}</Text><Text style={s.summaryText}>件值得記下的小事</Text></View>
          <View style={s.toolbar}>
            <Text style={s.section}>我的紀錄</Text>
            <Pressable accessibilityRole="button" accessibilityLabel="新增紀錄" disabled={!ready || saving} onPress={() => openEditor()} style={[s.primary, !ready && s.disabled]}><Feather name="plus" size={20} color="#fff" /><Text style={s.primaryText}>新增</Text></Pressable>
          </View>
          <View style={s.filters}>{(['全部', ...categories] as const).map(c => <Pressable key={c} accessibilityRole="tab" accessibilityState={{selected:filter === c}} accessibilityLabel={`篩選${c}`} onPress={() => setFilter(c)} style={[s.filter, filter===c && s.activeFilter]}><Text style={[s.filterText, filter===c && s.activeText]}>{c}</Text></Pressable>)}</View>
          {loadError ? <View style={s.empty}><Text style={s.error}>無法讀取已存的紀錄，原始資料尚未變更。</Text><Pressable accessibilityRole="button" onPress={load} style={s.secondary}><Text>重新讀取</Text></Pressable></View> : !ready ? <ActivityIndicator accessibilityLabel="讀取紀錄" color={color.green} /> : shown.length === 0 ? <View style={s.empty}><Feather name="book-open" size={36} color={color.green} /><Text style={s.emptyTitle}>{filter==='全部'?'記下今天第一件小事':`還沒有${filter}紀錄`}</Text></View> : shown.map(entry => <View key={entry.id} style={s.entry}>
            <View style={s.entryTop}><Text style={[s.category, entry.category === '靈感' && {color:color.coral}]}>{entry.category}</Text><Text style={s.date}>{new Date(entry.createdAt).toLocaleDateString('zh-TW',{month:'numeric',day:'numeric'})}</Text></View>
            <Text style={s.entryTitle}>{entry.title}</Text>{!!entry.body && <Text style={s.body}>{entry.body}</Text>}
            <View style={s.actions}><Pressable accessibilityRole="button" accessibilityLabel={`編輯${entry.title}`} onPress={() => openEditor(entry)} disabled={saving} style={s.iconButton}><Feather name="edit-2" size={19} color={color.green} /></Pressable><Pressable accessibilityRole="button" accessibilityLabel={`刪除${entry.title}`} onPress={() => {setDeleting(entry.id);setMessage('');}} disabled={saving} style={s.iconButton}><Feather name="trash-2" size={19} color={color.coral} /></Pressable></View>
            {deleting===entry.id && <View style={s.confirm}><Text style={s.body}>要刪除這筆紀錄嗎？</Text><View style={s.actions}><Pressable accessibilityRole="button" accessibilityLabel="取消刪除" disabled={saving} onPress={() => setDeleting(null)} style={s.secondary}><Text>取消</Text></Pressable><Pressable accessibilityRole="button" accessibilityLabel="確認刪除" disabled={saving} onPress={async () => {if(await persist(entries.filter(e => e.id!==entry.id),'已刪除'))setDeleting(null);}} style={s.danger}><Text style={s.primaryText}>確認刪除</Text></Pressable></View></View>}
          </View>)}
        </> : <>
          <View style={s.editorHeader}><Pressable accessibilityRole="button" accessibilityLabel="返回紀錄列表" onPress={() => {setEditing(undefined);setMessage('');}} disabled={saving} style={s.iconButton}><Feather name="arrow-left" size={25} color={color.ink} /></Pressable><Text style={s.editorTitle}>{editing===null?'新增小事':'編輯小事'}</Text></View>
          <Text style={s.label}>標題</Text><TextInput accessibilityLabel="標題" placeholder="今天完成了什麼？" placeholderTextColor={color.muted} value={draft.title} onChangeText={title=>setDraft({...draft,title})} maxLength={80} style={s.input} />
          <Text style={s.label}>內容</Text><TextInput accessibilityLabel="內容" placeholder="留下幾句話，給未來的自己。" placeholderTextColor={color.muted} value={draft.body} onChangeText={body=>setDraft({...draft,body})} multiline maxLength={2000} style={[s.input,s.textarea]} textAlignVertical="top" />
          <Text style={s.label}>分類</Text><View style={s.filters}>{categories.map(category=><Pressable key={category} accessibilityRole="radio" accessibilityState={{checked:draft.category===category}} accessibilityLabel={`分類${category}`} onPress={()=>setDraft({...draft,category})} style={[s.filter,draft.category===category && s.activeFilter]}><Text style={[s.filterText,draft.category===category && s.activeText]}>{category}</Text></Pressable>)}</View>
          <Pressable accessibilityRole="button" accessibilityLabel="儲存紀錄" disabled={saving} onPress={save} style={[s.primary,s.save,saving && s.disabled]}><Feather name="check" size={21} color="#fff" /><Text style={s.primaryText}>{saving?'儲存中…':'儲存紀錄'}</Text></Pressable>
        </>}
        {!!message && <Text accessibilityRole="alert" style={s.message}>{message}</Text>}
      </ScrollView>
    </KeyboardAvoidingView>
  </SafeAreaView>;
}

export default function App() { return <SafeAreaProvider><Journal /></SafeAreaProvider>; }

const s = StyleSheet.create({
  safe:{flex:1,backgroundColor:'#FFFFFF'},flex:{flex:1},page:{padding:24,paddingBottom:60,width:'100%',maxWidth:660,alignSelf:'center'},
  header:{flexDirection:'row',alignItems:'center',gap:16,marginTop:16},eyebrow:{fontSize:12,color:color.green,fontWeight:'700'},title:{fontSize:32,fontWeight:'700',color:color.ink,marginTop:6},brand:{width:56,height:56,alignItems:'center',justifyContent:'center'},
  summary:{flexDirection:'row',alignItems:'baseline',gap:12,paddingVertical:28,borderBottomWidth:1,borderBottomColor:color.border},count:{fontSize:46,fontWeight:'600',color:color.green},summaryText:{fontSize:16,color:color.muted,flexShrink:1},toolbar:{flexDirection:'row',alignItems:'center',justifyContent:'space-between',marginTop:26,marginBottom:16,gap:12},section:{fontSize:20,fontWeight:'600',color:color.ink},
  primary:{backgroundColor:color.green,borderRadius:8,paddingHorizontal:18,minHeight:46,flexDirection:'row',alignItems:'center',justifyContent:'center',gap:8},primaryText:{color:'#fff',fontSize:16,fontWeight:'600'},disabled:{opacity:0.45},
  filters:{flexDirection:'row',gap:8,flexWrap:'wrap',marginBottom:22},filter:{minHeight:44,paddingHorizontal:17,justifyContent:'center',borderRadius:6,backgroundColor:'#F3F5F4'},activeFilter:{backgroundColor:'#E0F0E9'},filterText:{fontSize:15,color:color.muted},activeText:{color:color.green,fontWeight:'700'},
  empty:{paddingVertical:42,alignItems:'center',gap:18},emptyTitle:{fontSize:18,color:color.muted,textAlign:'center'},entry:{paddingVertical:20,borderBottomWidth:1,borderBottomColor:color.border},entryTop:{flexDirection:'row',justifyContent:'space-between',alignItems:'center'},category:{color:color.green,fontSize:13,fontWeight:'600'},date:{fontSize:13,color:color.muted},entryTitle:{fontSize:22,fontWeight:'600',color:color.ink,marginTop:10},body:{fontSize:16,lineHeight:26,color:color.muted,marginTop:8},actions:{flexDirection:'row',justifyContent:'flex-end',gap:8,marginTop:8},iconButton:{width:44,height:44,alignItems:'center',justifyContent:'center'},confirm:{padding:16,backgroundColor:'#FFF1EE',borderRadius:8,marginTop:8},secondary:{minHeight:44,paddingHorizontal:16,justifyContent:'center',alignItems:'center'},danger:{minHeight:44,paddingHorizontal:16,justifyContent:'center',backgroundColor:color.coral,borderRadius:6},
  editorHeader:{flexDirection:'row',alignItems:'center',gap:12,marginBottom:30,marginTop:12},editorTitle:{fontSize:25,fontWeight:'700',color:color.ink},label:{fontSize:16,fontWeight:'600',color:color.ink,marginBottom:10},input:{fontSize:17,color:color.ink,borderWidth:1,borderColor:color.border,borderRadius:8,padding:14,minHeight:52,marginBottom:24},textarea:{minHeight:156},save:{marginTop:12},message:{fontSize:16,lineHeight:24,color:color.green,marginTop:20},error:{fontSize:16,lineHeight:25,color:color.coral},
});
