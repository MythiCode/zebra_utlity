package com.professor.zebrautility;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.net.Socket;
import android.content.Context;


public class Socketmanager 
{
	public static final  boolean MESSAGE_CONNECTED=true;
	public static final  boolean MESSAGE_CONNECTED_ERROR=false;
	public static final  boolean MESSAGE_WRITE_SUCCESS=true;
	public static final  boolean MESSAGE_WRITE_ERROR=false;
	private  Socket mMyWifiSocket=null;
	private BufferedReader BufReader= null;
	private OutputStream PriOut = null;
	private boolean iState=false;  
	
	public  String mstrIp="192.168.1.248";
	public  int mPort=9100;
	
	int TimeOut=1300;
	public boolean getIstate () {
		return iState;
	}
	public void threadconnect()
	{
		new ConnectThread();
	}
	
	public void threadconnectwrite(byte[] str)
	{
		new WriteThread(str);
	}
	
	public boolean connect()
	{
		close();
		try 
		{
			mMyWifiSocket = new Socket(); 
			mMyWifiSocket.connect(new InetSocketAddress(mstrIp,mPort),TimeOut);
			PriOut= mMyWifiSocket.getOutputStream();
			return true;
		} catch (IOException e) 
		{
			e.printStackTrace();
			SetState(MESSAGE_CONNECTED_ERROR);
			return false;
		}
	}
	
	
	public boolean write(byte[] out)
	{
		if(PriOut!=null)
		{
			try 
			{
				PriOut.write(out);
				PriOut.flush();
				return true;
			} catch (IOException e) 
			{
				e.printStackTrace();
				return false;
			}	
		}
		else
		{
				return false;
		}
	}
	
	public void close()
	{
		if(mMyWifiSocket!=null)
		{
			try 
			{
				mMyWifiSocket.close();
				mMyWifiSocket=null;
			} 
			catch (IOException e1) 
			{
				e1.printStackTrace();
			}
		}
		if(BufReader!=null)
		{
			try 
			{
				BufReader.close();
				BufReader=null;
			} catch (IOException e2) {
				e2.printStackTrace();
			}
		}
		if(PriOut!=null)
		{
			try 
			{
				PriOut.close();
			} catch (IOException e) {
				e.printStackTrace();
			}
			PriOut=null;
		}
	}
	
	public boolean ConnectAndWrite(byte[] out)
	{
		if(connect())
		{
			write(out);
			close();	
			SetState(MESSAGE_WRITE_SUCCESS);
			return true;
		}
		else
		{
			SetState(MESSAGE_CONNECTED_ERROR);
			return false;
		}
	}
	
	
	public Socketmanager(Context context)
	{
	}
	
	public void SetState(Boolean state)
	{
        iState=state;
	}
	
	private class ConnectThread extends Thread 
	{
		public ConnectThread()
		{
			start();
		}
		public void run() 
		{
			if(connect())
			{
				SetState(MESSAGE_CONNECTED);
			}
			close();
		}
	}
	private class WriteThread extends Thread 
	{
		byte[] out;
		public WriteThread(byte[] str)
		{
			out=str;
			start();
		}
		public void run() 
		{
			if(ConnectAndWrite(out))
			{
				SetState(MESSAGE_WRITE_SUCCESS);
			}
		}
	}
}
