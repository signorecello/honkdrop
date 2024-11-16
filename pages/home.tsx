/* eslint-disable react-native/no-inline-styles */
import React, {useEffect} from 'react';
import {Text, View} from 'react-native';
import MainLayout from '../layouts/MainLayout';
import Button from '../components/Button';
import {useNavigation} from '@react-navigation/native';
import {prepareSrs} from '../lib/noir';

export default function Home() {
  const navigation = useNavigation();

  useEffect(() => {
    // Load the local SRS (if present in resources) in internal storage
    // Only for Android, will be skipped on iOS
    prepareSrs();
  }, []);

  return (
    <MainLayout>
      <View
        style={{
          gap: 20,
        }}>
        <Button
          onPress={() => {
            navigation.navigate('Plume');
          }}>
          <Text
            style={{
              color: 'white',
              fontWeight: '700',
            }}>
            Plume
          </Text>
        </Button>
      </View>
    </MainLayout>
  );
}
