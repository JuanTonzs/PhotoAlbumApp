import { Button, StyleSheet, Text } from "react-native";
import { SafeAreaView } from 'react-native-safe-area-context';



export default function App() {
  return (
    <SafeAreaView style={styles.container}>
      <Text>Lorem ipsum dolor sit amet consectetur adipisicing elit. Illum magni, minus officia voluptatibus aliquam placeat debitis commodi ipsam aliquid! Porro eum nesciunt adipisci temporibus perspiciatis expedita consequuntur maiores aut quo.</Text>
      <Button onPress={() => console.log("Hello")} title="Learn More"/>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    justifyContent: 'space-between',
    alignItems: 'center',
  }
});

