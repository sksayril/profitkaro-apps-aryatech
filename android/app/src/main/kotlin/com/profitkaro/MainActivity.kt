package com.profitkaro

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.tapjoy.Tapjoy
import com.tapjoy.TJConnectListener
import com.tapjoy.TJPlacement
import com.tapjoy.TJPlacementListener
import com.tapjoy.TJActionRequest
import com.tapjoy.TJSetUserIDListener
import java.util.Hashtable

class MainActivity : FlutterActivity() {
    private val CHANNEL = "tapjoy_offerwall"
    private val BITLABS_CHANNEL = "bitlabs_offerwall"
    private val DEEP_LINK_CHANNEL = "deep_link"
    private var offerwallPlacement: TJPlacement? = null
    private var isContentReady = false
    private var isTapjoyConnected = false
    private var isBitLabsInitialized = false
    private var tapjoyChannel: MethodChannel? = null
    private var deepLinkChannel: MethodChannel? = null

    override fun onNewIntent(intent: android.content.Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleDeepLink(intent)
    }

    private fun handleDeepLink(intent: android.content.Intent?) {
        if (intent == null) return
        
        val data = intent.data
        if (data != null) {
            val url = data.toString()
            System.out.println("MainActivity: Deep link received: $url")

            try {
                deepLinkChannel?.invokeMethod(
                    "onDeepLink",
                    mapOf("url" to url)
                )
            } catch (e: IllegalStateException) {
                System.out.println("MainActivity: Deep link delivery skipped (engine not ready): ${e.message}")
            } catch (e: Exception) {
                System.out.println("MainActivity: Deep link delivery failed: ${e.message}")
            }
        }
    }

    override fun onStart() {
        super.onStart()
        System.out.println("Tapjoy: ===== onStart() - Initializing Tapjoy SDK =====")
        
        val sdkKey = "Z9Y4_msqSmGbgZLCWzsPogECs9zdQNwI88Y6MOAqjPxyCKIJle9HYmysHYoc"
        val flags = Hashtable<String, Any>()
        
        Tapjoy.connect(applicationContext, sdkKey, flags, object : TJConnectListener() {
            override fun onConnectSuccess() {
                isTapjoyConnected = true
                System.out.println("Tapjoy: ✓✓✓ SDK CONNECTED SUCCESSFULLY")
                
                // Set currency listener
                Tapjoy.setEarnedCurrencyListener { currencyName, amount ->
                    System.out.println("Tapjoy: Currency earned - $amount $currencyName")
                    notifyFlutterOfReward(currencyName, amount)
                }
                
                // Initialize placement immediately after connection
                initializePlacement()
            }

            override fun onConnectFailure(errorCode: Int, errorMessage: String?) {
                isTapjoyConnected = false
                System.out.println("Tapjoy: ✗✗✗ CONNECTION FAILED")
                System.out.println("Tapjoy: Error code: $errorCode, message: $errorMessage")
            }
            
            override fun onConnectWarning(warningCode: Int, warningMessage: String?) {
                System.out.println("Tapjoy: ⚠ WARNING - Code: $warningCode, Message: $warningMessage")
            }
        })
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        tapjoyChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        deepLinkChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DEEP_LINK_CHANNEL)
        handleDeepLink(intent)

        tapjoyChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "showOfferwall" -> {
                    val showed = showOfferwall()
                    result.success(showed)
                }
                "isContentReady" -> {
                    result.success(isContentReady)
                }
                "prepareOfferwall" -> {
                    initializePlacement()
                    result.success(true)
                }
                "setUserID" -> {
                    val userId = call.argument<String>("userId")
                    if (userId != null && userId.isNotEmpty()) {
                        Tapjoy.setUserID(userId, object : TJSetUserIDListener {
                            override fun onSetUserIDSuccess() {
                                System.out.println("Tapjoy: UserID set successfully: $userId")
                            }
                            override fun onSetUserIDFailure(error: String?) {
                                System.out.println("Tapjoy: UserID set failed: $error")
                            }
                        })
                    }
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // BitLabs Method Channel Handler
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BITLABS_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "init" -> {
                    val apiToken = call.argument<String>("apiToken")
                    val secretKey = call.argument<String>("secretKey")
                    System.out.println("BitLabs: Initializing with API Token: $apiToken")
                    // TODO: Initialize BitLabs SDK here when SDK is available
                    // For now, we'll mark as initialized
                    isBitLabsInitialized = true
                    result.success(true)
                }
                "setUserID" -> {
                    val userId = call.argument<String>("userId")
                    if (userId != null && userId.isNotEmpty()) {
                        System.out.println("BitLabs: UserID set: $userId")
                        // TODO: Set BitLabs User ID when SDK is available
                    }
                    result.success(true)
                }
                "prepareOfferwall" -> {
                    System.out.println("BitLabs: Preparing offerwall...")
                    // TODO: Prepare BitLabs offerwall when SDK is available
                    result.success(true)
                }
                "isContentReady" -> {
                    // TODO: Check BitLabs content ready status when SDK is available
                    result.success(false)
                }
                "showOfferwall" -> {
                    System.out.println("BitLabs: Attempting to show offerwall...")
                    // TODO: Show BitLabs offerwall when SDK is available
                    // For now, return false - this will be implemented when BitLabs SDK is added
                    System.out.println("BitLabs: ⚠ SDK not yet integrated - Please add BitLabs SDK to build.gradle")
                    result.success(false)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun initializePlacement() {
        if (!isTapjoyConnected) {
            System.out.println("Tapjoy: Cannot initialize placement - SDK not connected")
            return
        }
        
        System.out.println("Tapjoy: ===== Initializing Placement: offerwall_card =====")
        
        // If placement already exists, just request content
        if (offerwallPlacement != null) {
            System.out.println("Tapjoy: Placement exists, requesting content...")
            offerwallPlacement?.requestContent()
            return
        }
        
        // Create new placement
        offerwallPlacement = Tapjoy.getPlacement("offerwall_card", object : TJPlacementListener {
            override fun onRequestSuccess(placement: TJPlacement?) {
                System.out.println("Tapjoy: ✓ Placement Request SUCCESS")
                System.out.println("Tapjoy: Placement name: ${placement?.name}")
                // Request content immediately
                placement?.requestContent()
            }
            
            override fun onRequestFailure(placement: TJPlacement?, error: com.tapjoy.TJError?) {
                System.out.println("Tapjoy: ✗ Placement Request FAILED")
                System.out.println("Tapjoy: Error code: ${error?.code}, message: ${error?.message}")
                isContentReady = false
            }
            
            override fun onContentReady(placement: TJPlacement?) {
                System.out.println("Tapjoy: ✓✓✓ CONTENT READY - Offers available!")
                System.out.println("Tapjoy: Placement isContentReady: ${placement?.isContentReady}")
                isContentReady = true
            }
            
            override fun onContentShow(placement: TJPlacement?) {
                System.out.println("Tapjoy: ✓ Offerwall is now VISIBLE")
            }
            
            override fun onContentDismiss(placement: TJPlacement?) {
                System.out.println("Tapjoy: Offerwall DISMISSED")
                isContentReady = false
                // Request new content for next time
                placement?.requestContent()
            }
            
            override fun onPurchaseRequest(placement: TJPlacement?, request: TJActionRequest?, productId: String?) {
                System.out.println("Tapjoy: Purchase request: $productId")
            }
            
            override fun onRewardRequest(placement: TJPlacement?, request: TJActionRequest?, productId: String?, amount: Int) {
                System.out.println("Tapjoy: Reward request: $productId, amount: $amount")
            }
            
            override fun onClick(placement: TJPlacement?) {
                System.out.println("Tapjoy: User clicked on offer")
            }
        })
        
        // Request content immediately
        System.out.println("Tapjoy: Requesting content for placement...")
        offerwallPlacement?.requestContent()
        
        // Check content status after delays
        android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
            if (offerwallPlacement != null) {
                val ready = offerwallPlacement?.isContentReady == true
                System.out.println("Tapjoy: Content status after 2 seconds: ready=$ready, flag=$isContentReady")
            }
        }, 2000)
        
        android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
            if (offerwallPlacement != null) {
                val ready = offerwallPlacement?.isContentReady == true
                System.out.println("Tapjoy: Content status after 5 seconds: ready=$ready, flag=$isContentReady")
                if (!ready) {
                    System.out.println("Tapjoy: ⚠ Content still not ready - likely no offers available")
                }
            }
        }, 5000)
    }

    private fun showOfferwall(): Boolean {
        System.out.println("Tapjoy: ===== showOfferwall() called =====")
        
        // Ensure Tapjoy is connected
        if (!isTapjoyConnected) {
            System.out.println("Tapjoy: ✗ SDK not connected, cannot show offerwall")
            return false
        }
        
        // Ensure placement exists
        if (offerwallPlacement == null) {
            System.out.println("Tapjoy: ✗ Placement is null, initializing...")
            initializePlacement()
            // Never block main thread; let caller retry if placement is still not ready.
            return false
        }
        
        if (offerwallPlacement == null) {
            System.out.println("Tapjoy: ✗✗✗ Placement still null after initialization")
            return false
        }
        
        System.out.println("Tapjoy: Placement exists: ${offerwallPlacement?.name}")
        System.out.println("Tapjoy: Content ready status: $isContentReady")
        System.out.println("Tapjoy: Placement content ready: ${offerwallPlacement?.isContentReady}")
        
        // Request content again if not ready
        if (!isContentReady) {
            System.out.println("Tapjoy: Content not ready, requesting again...")
            offerwallPlacement?.requestContent()
            // Never block main thread; caller can retry once placement becomes ready.
            return false
        }
        
        // Check if content is ready now
        val placementReady = offerwallPlacement?.isContentReady == true
        System.out.println("Tapjoy: Final check - Placement ready: $placementReady, Flag ready: $isContentReady")
        
        // Only show if content is actually ready
        // Tapjoy SDK will throw error if we try to show non-200 placement
        if (!placementReady && !isContentReady) {
            System.out.println("Tapjoy: ✗✗✗ Cannot show - Content not available (non-200 placement)")
            System.out.println("Tapjoy: Error: 'No placement content available. Can not show content for non-200 placement.'")
            System.out.println("Tapjoy: ===== SOLUTION =====")
            System.out.println("Tapjoy: 1. Go to Tapjoy Dashboard")
            System.out.println("Tapjoy: 2. Check placement 'offerwall_card'")
            System.out.println("Tapjoy: 3. Ensure offers are ACTIVE and PUBLISHED")
            System.out.println("Tapjoy: 4. Check that offers are assigned to this placement")
            System.out.println("Tapjoy: 5. Verify app is linked correctly in Tapjoy dashboard")
            return false
        }
        
        // Try to show the offerwall
        return try {
            System.out.println("Tapjoy: Attempting to SHOW offerwall...")
            offerwallPlacement?.showContent()
            System.out.println("Tapjoy: ✓✓✓ showContent() called successfully")
            true
        } catch (e: Exception) {
            System.out.println("Tapjoy: ✗✗✗ ERROR showing offerwall: ${e.message}")
            System.out.println("Tapjoy: Exception: ${e.javaClass.simpleName}")
            e.printStackTrace()
            false
        }
    }

    private fun notifyFlutterOfReward(currencyName: String?, amount: Int) {
        runOnUiThread {
            try {
                tapjoyChannel?.invokeMethod(
                    "onRewardEarned",
                    mapOf("currency" to currencyName, "amount" to amount)
                )
            } catch (e: IllegalStateException) {
                System.out.println("Tapjoy: Reward callback skipped (engine not ready): ${e.message}")
            } catch (e: Exception) {
                System.out.println("Tapjoy: Reward callback failed: ${e.message}")
            }
        }
    }
}
