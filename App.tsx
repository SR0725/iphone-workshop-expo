import { StatusBar } from 'expo-status-bar';
import { Platform, StyleSheet, Text, View } from 'react-native';

export default function App() {
  return (
    <View style={styles.container}>
      <Text style={styles.eyebrow}>SMALL THINGS</Text>
      <Text style={styles.title}>今天的小事</Text>
      <Text style={styles.count}>0 件紀錄</Text>
      <View style={styles.badge}>
        <Text style={styles.badgeText}>
          {Platform.OS === 'web' ? '電腦預覽已開啟' : '已在手機上跑起來了'}
        </Text>
      </View>
      <Text style={styles.note}>接下來請 Codex 讀 PRD.md 與 design，做出清單和新增畫面。</Text>
      <StatusBar style="dark" />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#FFFFFF', padding: 28, justifyContent: 'center' },
  eyebrow: { color: '#176B53', fontSize: 12, fontWeight: '700', letterSpacing: 1 },
  title: { color: '#172921', fontSize: 34, fontWeight: '700', marginTop: 6 },
  count: { color: '#66736D', fontSize: 18, marginTop: 14 },
  badge: { alignSelf: 'flex-start', backgroundColor: '#E0F0E9', borderRadius: 999, paddingHorizontal: 14, paddingVertical: 8, marginTop: 28 },
  badgeText: { color: '#176B53', fontSize: 15, fontWeight: '600' },
  note: { color: '#66736D', fontSize: 15, lineHeight: 23, marginTop: 14 },
});
